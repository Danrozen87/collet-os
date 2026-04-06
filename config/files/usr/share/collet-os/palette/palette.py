#!/usr/bin/env python3
"""
Collet OS Command Palette
A minimal Spotlight/Raycast-style overlay for GNOME on Fedora Atomic.

Launches apps, opens files, navigates settings, and queries local AI (Ollama).
Toggled via Super+Space (bound in GNOME keyboard shortcuts to `collet-palette`).

Dependencies: GTK4, libadwaita, PyGObject — all present on Silverblue base.
"""

import gi
import json
import os
import subprocess
import threading
import urllib.request
import urllib.error
from datetime import datetime
from pathlib import Path

gi.require_version("Gtk", "4.0")
gi.require_version("Adw", "1")
gi.require_version("Gio", "2.0")

from gi.repository import Gtk, Adw, Gio, GLib, Gdk, Pango  # noqa: E402


# ── Configuration ────────────────────────────────────────────────────────────

OLLAMA_ENDPOINT = "http://localhost:11434"
OLLAMA_MODEL = "collet-assistant"
SYSTEM_PROMPT_FILE = "/usr/share/collet-os/ai/system-prompt.md"
BACKEND_CONFIG = "/usr/share/collet-os/ai/backend.toml"
USER_BACKEND_CONFIG = os.path.expanduser("~/.config/collet-os/ai/backend.toml")
AUDIT_DIR = os.path.expanduser("~/.local/share/collet-os/audit")
MAX_RESULTS = 8
AI_PREFIX = "?"  # Queries starting with ? go directly to AI
AI_TIMEOUT = 15  # seconds


def load_backend_config():
    """Read backend.toml to get endpoint and model."""
    global OLLAMA_ENDPOINT, OLLAMA_MODEL
    for config_path in [BACKEND_CONFIG, USER_BACKEND_CONFIG]:
        if not os.path.isfile(config_path):
            continue
        try:
            with open(config_path) as f:
                for line in f:
                    line = line.strip()
                    if line.startswith("endpoint"):
                        val = line.split("=", 1)[1].strip().strip('"')
                        OLLAMA_ENDPOINT = val
                    elif line.startswith("model"):
                        val = line.split("=", 1)[1].strip().strip('"')
                        OLLAMA_MODEL = val
        except OSError:
            pass


def load_system_prompt():
    """Load the Collet OS system prompt for AI queries."""
    if os.path.isfile(SYSTEM_PROMPT_FILE):
        with open(SYSTEM_PROMPT_FILE) as f:
            return f.read()
    return (
        "You are the Collet OS assistant. Answer concisely in 1-3 sentences. "
        "If the user asks for a command, show the command and a one-line explanation. "
        "Detect the user's language and respond in it."
    )


def audit_log(action, query, result=""):
    """Append to the Collet OS audit trail."""
    try:
        os.makedirs(AUDIT_DIR, exist_ok=True)
        ts = datetime.now().isoformat(timespec="seconds")
        with open(os.path.join(AUDIT_DIR, "palette.log"), "a") as f:
            f.write(f"{ts} | PALETTE | {action} | {query} | {result}\n")
    except OSError:
        pass


# ── Result types ─────────────────────────────────────────────────────────────

class PaletteResult:
    """A single result row in the command palette."""

    __slots__ = ("title", "description", "icon_name", "action", "category")

    def __init__(self, title, description="", icon_name="", action=None, category=""):
        self.title = title
        self.description = description
        self.icon_name = icon_name or "application-x-executable-symbolic"
        self.action = action or (lambda: None)
        self.category = category


# ── Search providers ─────────────────────────────────────────────────────────

def search_applications(query):
    """Search installed .desktop applications."""
    results = []
    query_lower = query.lower()

    app_dirs = [
        "/usr/share/applications",
        "/var/lib/flatpak/exports/share/applications",
        os.path.expanduser("~/.local/share/flatpak/exports/share/applications"),
        os.path.expanduser("~/.local/share/applications"),
    ]

    seen = set()
    for app_dir in app_dirs:
        if not os.path.isdir(app_dir):
            continue
        for fname in os.listdir(app_dir):
            if not fname.endswith(".desktop") or fname in seen:
                continue
            seen.add(fname)
            filepath = os.path.join(app_dir, fname)
            try:
                app_info = Gio.DesktopAppInfo.new_from_filename(filepath)
                if app_info is None or app_info.get_nodisplay():
                    continue
                name = app_info.get_display_name() or ""
                generic = app_info.get_generic_name() or ""
                keywords = " ".join(app_info.get_keywords() or [])
                searchable = f"{name} {generic} {keywords}".lower()
                if query_lower in searchable:
                    icon = app_info.get_icon()
                    icon_name = icon.to_string() if icon else "application-x-executable-symbolic"
                    results.append(PaletteResult(
                        title=name,
                        description=generic or "Application",
                        icon_name=icon_name,
                        action=lambda ai=app_info: ai.launch([], None),
                        category="app",
                    ))
            except Exception:
                continue

    # Sort: exact prefix match first, then alphabetical
    results.sort(key=lambda r: (not r.title.lower().startswith(query_lower), r.title.lower()))
    return results[:MAX_RESULTS]


def search_settings(query):
    """Map natural language to GNOME Settings panels."""
    settings_map = [
        (["wifi", "wi-fi", "wireless", "network", "internet", "wlan"],
         "Wi-Fi", "network-wireless-symbolic", "gnome-control-center wifi"),
        (["bluetooth", "bt"],
         "Bluetooth", "bluetooth-symbolic", "gnome-control-center bluetooth"),
        (["display", "screen", "monitor", "resolution", "refresh"],
         "Displays", "video-display-symbolic", "gnome-control-center display"),
        (["sound", "audio", "volume", "speaker", "microphone"],
         "Sound", "audio-volume-high-symbolic", "gnome-control-center sound"),
        (["power", "battery", "energy", "suspend", "sleep"],
         "Power", "battery-symbolic", "gnome-control-center power"),
        (["keyboard", "shortcut", "hotkey", "keybinding"],
         "Keyboard", "input-keyboard-symbolic", "gnome-control-center keyboard"),
        (["mouse", "touchpad", "trackpad", "pointer"],
         "Mouse & Touchpad", "input-mouse-symbolic", "gnome-control-center mouse"),
        (["printer", "print", "scanner"],
         "Printers", "printer-symbolic", "gnome-control-center printers"),
        (["user", "account", "login", "password"],
         "Users", "system-users-symbolic", "gnome-control-center user-accounts"),
        (["appearance", "theme", "dark", "light", "wallpaper", "background"],
         "Appearance", "preferences-desktop-wallpaper-symbolic", "gnome-control-center background"),
        (["date", "time", "timezone", "clock"],
         "Date & Time", "preferences-system-time-symbolic", "gnome-control-center datetime"),
        (["region", "language", "locale", "input method"],
         "Region & Language", "preferences-desktop-locale-symbolic", "gnome-control-center region"),
        (["accessibility", "a11y", "font size", "text bigger", "zoom"],
         "Accessibility", "preferences-desktop-accessibility-symbolic", "gnome-control-center universal-access"),
        (["privacy", "location", "tracking", "diagnostics"],
         "Privacy", "preferences-system-privacy-symbolic", "gnome-control-center privacy"),
        (["about", "system info", "os", "hostname", "specs"],
         "About", "help-about-symbolic", "gnome-control-center info-overview"),
        (["update", "software", "upgrade"],
         "Software Updates", "software-update-available-symbolic", "gnome-software --mode=updates"),
        (["sharing", "remote desktop", "rdp", "vnc", "file sharing"],
         "Sharing", "preferences-system-sharing-symbolic", "gnome-control-center sharing"),
        (["notifications", "do not disturb"],
         "Notifications", "preferences-system-notifications-symbolic", "gnome-control-center notifications"),
        (["default apps", "default applications", "browser", "email client"],
         "Default Applications", "application-x-executable-symbolic", "gnome-control-center default-apps"),
        (["online accounts", "google", "nextcloud"],
         "Online Accounts", "goa-panel-symbolic", "gnome-control-center online-accounts"),
    ]

    query_lower = query.lower()
    results = []
    for keywords, label, icon, cmd in settings_map:
        if any(kw in query_lower for kw in keywords):
            results.append(PaletteResult(
                title=label,
                description="Settings",
                icon_name=icon,
                action=lambda c=cmd: subprocess.Popen(c.split()),
                category="settings",
            ))

    return results[:MAX_RESULTS]


def search_recent_files(query):
    """Search recently used files via GtkRecentManager."""
    results = []
    query_lower = query.lower()

    manager = Gtk.RecentManager.get_default()
    items = manager.get_items()

    for item in items:
        display_name = item.get_display_name() or ""
        uri = item.get_uri() or ""
        if query_lower in display_name.lower():
            mime = item.get_mime_type() or ""
            icon_name = "text-x-generic-symbolic"
            if "image" in mime:
                icon_name = "image-x-generic-symbolic"
            elif "video" in mime:
                icon_name = "video-x-generic-symbolic"
            elif "audio" in mime:
                icon_name = "audio-x-generic-symbolic"
            elif "pdf" in mime:
                icon_name = "x-office-document-symbolic"
            elif "folder" in mime or "directory" in mime:
                icon_name = "folder-symbolic"

            results.append(PaletteResult(
                title=display_name,
                description=uri.replace("file://", "").replace(os.path.expanduser("~"), "~"),
                icon_name=icon_name,
                action=lambda u=uri: subprocess.Popen(["xdg-open", u]),
                category="file",
            ))

    results.sort(key=lambda r: r.title.lower())
    return results[:MAX_RESULTS]


# ── AI provider ──────────────────────────────────────────────────────────────

def query_ollama(query, callback):
    """Query Ollama in a background thread, call callback(response) on the main thread."""
    def _worker():
        try:
            system_prompt = load_system_prompt()
            payload = json.dumps({
                "model": OLLAMA_MODEL,
                "messages": [
                    {"role": "system", "content": system_prompt},
                    {"role": "user", "content": query},
                ],
                "stream": False,
                "options": {"temperature": 0.3, "num_predict": 300},
            }).encode()

            req = urllib.request.Request(
                f"{OLLAMA_ENDPOINT}/api/chat",
                data=payload,
                headers={"Content-Type": "application/json"},
                method="POST",
            )
            with urllib.request.urlopen(req, timeout=AI_TIMEOUT) as resp:
                data = json.loads(resp.read())
                answer = data.get("message", {}).get("content", "").strip()
                audit_log("AI_QUERY", query, answer[:100])
                GLib.idle_add(callback, answer)
        except urllib.error.URLError:
            GLib.idle_add(callback, "AI is not available. Is Ollama running?")
        except Exception as e:
            GLib.idle_add(callback, f"Error: {e}")

    thread = threading.Thread(target=_worker, daemon=True)
    thread.start()


# ── Main application ─────────────────────────────────────────────────────────

class ColletPalette(Adw.Application):
    """The command palette application."""

    def __init__(self):
        super().__init__(
            application_id="org.collet.Palette",
            flags=Gio.ApplicationFlags.HANDLES_COMMAND_LINE,
        )
        self.window = None
        self.search_entry = None
        self.results_box = None
        self.ai_row = None
        self.selected_index = -1
        self.result_rows = []
        self._search_timeout_id = None

    def do_activate(self):
        if self.window is not None:
            # Toggle: if already visible, hide; otherwise show
            if self.window.is_visible():
                self.window.set_visible(False)
                return
            else:
                self.search_entry.set_text("")
                self._clear_results()
                self.window.set_visible(True)
                self.window.present()
                self.search_entry.grab_focus()
                return

        self._build_ui()

    def do_command_line(self, command_line):
        self.activate()
        return 0

    def _build_ui(self):
        # Load custom CSS
        css_path = "/usr/share/collet-os/palette/style.css"
        if os.path.isfile(css_path):
            css_provider = Gtk.CssProvider()
            css_provider.load_from_path(css_path)
            Gtk.StyleContext.add_provider_for_display(
                Gdk.Display.get_default(),
                css_provider,
                Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION,
            )

        # Window
        self.window = Adw.ApplicationWindow(application=self)
        self.window.set_default_size(680, -1)  # Width only; height is content-driven
        self.window.set_resizable(False)
        self.window.set_decorated(False)
        self.window.set_title("")
        self.window.add_css_class("palette-window")

        # Center on screen
        # On Wayland, we rely on the WM to center (GNOME centers new windows
        # when org.gnome.mutter center-new-windows is true, which Collet OS sets)

        # Main container
        main_box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=0)
        main_box.add_css_class("palette-container")

        # Search entry
        self.search_entry = Gtk.SearchEntry()
        self.search_entry.set_placeholder_text("Search apps, files, settings, or ask AI...")
        self.search_entry.set_hexpand(True)
        self.search_entry.add_css_class("palette-search")

        # Search entry container with padding
        search_box = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL)
        search_box.set_margin_start(16)
        search_box.set_margin_end(16)
        search_box.set_margin_top(12)
        search_box.set_margin_bottom(8)
        search_box.append(self.search_entry)

        main_box.append(search_box)

        # Separator
        sep = Gtk.Separator(orientation=Gtk.Orientation.HORIZONTAL)
        sep.add_css_class("palette-separator")
        main_box.append(sep)

        # Results area (scrollable)
        scrolled = Gtk.ScrolledWindow()
        scrolled.set_policy(Gtk.PolicyType.NEVER, Gtk.PolicyType.AUTOMATIC)
        scrolled.set_max_content_height(420)
        scrolled.set_propagate_natural_height(True)

        self.results_box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=0)
        self.results_box.set_margin_start(8)
        self.results_box.set_margin_end(8)
        self.results_box.set_margin_top(4)
        self.results_box.set_margin_bottom(8)
        scrolled.set_child(self.results_box)
        main_box.append(scrolled)

        # Hint bar at the bottom
        hint_bar = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=12)
        hint_bar.set_margin_start(16)
        hint_bar.set_margin_end(16)
        hint_bar.set_margin_bottom(8)
        hint_bar.set_margin_top(4)
        hint_bar.add_css_class("palette-hints")

        for key, action_text in [("Enter", "Open"), ("Esc", "Close"), ("?", "Ask AI")]:
            key_label = Gtk.Label(label=key)
            key_label.add_css_class("palette-key")
            action_label = Gtk.Label(label=action_text)
            action_label.add_css_class("palette-hint-text")
            pair = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=4)
            pair.append(key_label)
            pair.append(action_label)
            hint_bar.append(pair)

        main_box.append(hint_bar)

        self.window.set_content(main_box)

        # Connect signals
        self.search_entry.connect("search-changed", self._on_search_changed)

        # Key controller for navigation
        key_ctrl = Gtk.EventControllerKey()
        key_ctrl.connect("key-pressed", self._on_key_pressed)
        self.window.add_controller(key_ctrl)

        # Focus-out closes the palette (click outside)
        focus_ctrl = Gtk.EventControllerFocus()
        focus_ctrl.connect("leave", self._on_focus_out)
        self.window.add_controller(focus_ctrl)

        self.window.present()
        self.search_entry.grab_focus()

    def _on_focus_out(self, controller):
        """Close when the window loses focus."""
        # Small delay to avoid closing during internal focus changes
        GLib.timeout_add(150, self._check_focus)

    def _check_focus(self):
        if self.window and not self.window.is_active():
            self.window.set_visible(False)
        return False

    def _on_search_changed(self, entry):
        """Debounced search: wait 150ms after typing stops."""
        if self._search_timeout_id is not None:
            GLib.source_remove(self._search_timeout_id)
        self._search_timeout_id = GLib.timeout_add(150, self._do_search)

    def _do_search(self):
        self._search_timeout_id = None
        query = self.search_entry.get_text().strip()

        self._clear_results()

        if not query:
            return False

        # AI direct query (prefix with ?)
        if query.startswith(AI_PREFIX) and len(query) > 1:
            ai_query = query[len(AI_PREFIX):].strip()
            if ai_query:
                self._show_ai_loading(ai_query)
                query_ollama(ai_query, self._on_ai_response)
            return False

        # Parallel search across providers
        results = []
        results.extend(search_applications(query))
        results.extend(search_settings(query))

        if len(query) >= 3:
            results.extend(search_recent_files(query))

        # Deduplicate by title
        seen_titles = set()
        unique = []
        for r in results:
            if r.title not in seen_titles:
                seen_titles.add(r.title)
                unique.append(r)

        # Show results
        for r in unique[:MAX_RESULTS]:
            self._add_result_row(r)

        # If few results and query is long enough, offer AI fallback
        if len(unique) < 3 and len(query) >= 4:
            self._add_ai_suggestion(query)

        # Select first result
        if self.result_rows:
            self.selected_index = 0
            self._update_selection()

        return False

    def _clear_results(self):
        self.result_rows.clear()
        self.selected_index = -1
        self.ai_row = None
        child = self.results_box.get_first_child()
        while child:
            next_child = child.get_next_sibling()
            self.results_box.remove(child)
            child = next_child

    def _add_result_row(self, result):
        """Add a result row to the results list."""
        row = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=12)
        row.set_margin_start(8)
        row.set_margin_end(8)
        row.set_margin_top(4)
        row.set_margin_bottom(4)
        row.add_css_class("palette-row")

        # Icon
        icon = Gtk.Image.new_from_icon_name(result.icon_name)
        icon.set_pixel_size(24)
        icon.add_css_class("palette-row-icon")
        row.append(icon)

        # Text
        text_box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=2)
        text_box.set_hexpand(True)

        title_label = Gtk.Label(label=result.title, xalign=0)
        title_label.set_ellipsize(Pango.EllipsizeMode.END)
        title_label.add_css_class("palette-row-title")
        text_box.append(title_label)

        if result.description:
            desc_label = Gtk.Label(label=result.description, xalign=0)
            desc_label.set_ellipsize(Pango.EllipsizeMode.END)
            desc_label.add_css_class("palette-row-description")
            text_box.append(desc_label)

        row.append(text_box)

        # Category badge
        if result.category:
            badge = Gtk.Label(label=result.category)
            badge.add_css_class("palette-badge")
            row.append(badge)

        # Click handler
        click = Gtk.GestureClick()
        click.connect("pressed", lambda g, n, x, y, r=result: self._activate_result(r))
        row.add_controller(click)

        self.results_box.append(row)
        self.result_rows.append((row, result))

    def _add_ai_suggestion(self, query):
        """Add an 'Ask AI' suggestion row."""
        result = PaletteResult(
            title=f"Ask AI: {query}",
            description="Query the local AI assistant",
            icon_name="system-help-symbolic",
            action=None,
            category="ai",
        )

        def ai_action():
            self._clear_results()
            self._show_ai_loading(query)
            query_ollama(query, self._on_ai_response)

        result.action = ai_action
        self._add_result_row(result)

    def _show_ai_loading(self, query):
        """Show a loading indicator while AI processes."""
        spinner_box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=8)
        spinner_box.set_margin_top(16)
        spinner_box.set_margin_bottom(16)
        spinner_box.set_halign(Gtk.Align.CENTER)

        spinner = Gtk.Spinner()
        spinner.set_size_request(32, 32)
        spinner.start()
        spinner_box.append(spinner)

        label = Gtk.Label(label="Thinking...")
        label.add_css_class("palette-row-description")
        spinner_box.append(label)

        self.results_box.append(spinner_box)

    def _on_ai_response(self, response):
        """Display AI response in the results area."""
        self._clear_results()

        if not response:
            response = "No response received."

        # Response container
        response_box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=8)
        response_box.set_margin_start(12)
        response_box.set_margin_end(12)
        response_box.set_margin_top(8)
        response_box.set_margin_bottom(8)
        response_box.add_css_class("palette-ai-response")

        # AI label
        ai_label = Gtk.Label(label="AI", xalign=0)
        ai_label.add_css_class("palette-badge")
        response_box.append(ai_label)

        # Response text
        text_label = Gtk.Label(label=response, xalign=0)
        text_label.set_wrap(True)
        text_label.set_wrap_mode(Pango.WrapMode.WORD_CHAR)
        text_label.set_selectable(True)
        text_label.add_css_class("palette-ai-text")
        response_box.append(text_label)

        # Action buttons
        button_box = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=8)
        button_box.set_margin_top(4)

        copy_btn = Gtk.Button(label="Copy")
        copy_btn.add_css_class("palette-action-btn")
        copy_btn.connect("clicked", lambda b: self._copy_to_clipboard(response))
        button_box.append(copy_btn)

        close_btn = Gtk.Button(label="Close")
        close_btn.add_css_class("palette-action-btn")
        close_btn.connect("clicked", lambda b: self.window.set_visible(False))
        button_box.append(close_btn)

        response_box.append(button_box)
        self.results_box.append(response_box)

    def _copy_to_clipboard(self, text):
        """Copy text to clipboard using wl-copy (Wayland)."""
        try:
            proc = subprocess.Popen(
                ["wl-copy"], stdin=subprocess.PIPE, stderr=subprocess.DEVNULL,
            )
            proc.communicate(input=text.encode())
        except FileNotFoundError:
            # Fallback: GTK clipboard
            clipboard = Gdk.Display.get_default().get_clipboard()
            clipboard.set(text)

    def _activate_result(self, result):
        """Execute the result's action and hide the palette."""
        if result.action:
            audit_log("ACTIVATE", result.title, result.category)
            self.window.set_visible(False)
            try:
                result.action()
            except Exception as e:
                audit_log("ERROR", result.title, str(e))

    def _on_key_pressed(self, controller, keyval, keycode, state):
        """Handle keyboard navigation."""
        if keyval == Gdk.KEY_Escape:
            self.window.set_visible(False)
            return True

        if keyval == Gdk.KEY_Down:
            if self.result_rows:
                self.selected_index = min(
                    self.selected_index + 1, len(self.result_rows) - 1
                )
                self._update_selection()
            return True

        if keyval == Gdk.KEY_Up:
            if self.result_rows:
                self.selected_index = max(self.selected_index - 1, 0)
                self._update_selection()
            return True

        if keyval in (Gdk.KEY_Return, Gdk.KEY_KP_Enter):
            if 0 <= self.selected_index < len(self.result_rows):
                _, result = self.result_rows[self.selected_index]
                self._activate_result(result)
            return True

        if keyval == Gdk.KEY_Tab:
            # Tab selects next, shift+tab selects previous
            if state & Gdk.ModifierType.SHIFT_MASK:
                self.selected_index = max(self.selected_index - 1, 0)
            else:
                self.selected_index = min(
                    self.selected_index + 1, len(self.result_rows) - 1
                )
            self._update_selection()
            return True

        return False

    def _update_selection(self):
        """Highlight the currently selected row."""
        for i, (row, _) in enumerate(self.result_rows):
            if i == self.selected_index:
                row.add_css_class("palette-row-selected")
            else:
                row.remove_css_class("palette-row-selected")


# ── Entry point ──────────────────────────────────────────────────────────────

def main():
    load_backend_config()
    app = ColletPalette()
    app.run(None)


if __name__ == "__main__":
    main()
