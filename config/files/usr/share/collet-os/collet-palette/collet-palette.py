#!/usr/bin/env python3
"""
Collet OS — Command Palette
Super+Space launcher: apps, files, settings, AI queries in one box.
GTK4 + libadwaita, zero external dependencies.
"""

import gi
gi.require_version('Gtk', '4.0')
gi.require_version('Adw', '1')

import json
import os
import subprocess
import threading
import urllib.request
from pathlib import Path

from gi.repository import Adw, Gio, GLib, Gtk

OLLAMA_HOST = os.environ.get("OLLAMA_HOST", "http://localhost:11434")
OLLAMA_MODEL = os.environ.get("OLLAMA_MODEL", "llama3.2:3b")
AUDIT_DIR = Path(os.environ.get("XDG_DATA_HOME", Path.home() / ".local/share")) / "collet-os/audit"


class ColletPalette(Adw.Application):
    def __init__(self):
        super().__init__(application_id="eu.collet.palette",
                         flags=Gio.ApplicationFlags.FLAGS_NONE)
        self.apps = []
        self.window = None

    def do_activate(self):
        if self.window:
            self.window.present()
            return

        self.apps = self._load_apps()
        self.window = PaletteWindow(application=self, apps=self.apps)
        self.window.present()

    def _load_apps(self):
        """Scan .desktop files for launchable applications."""
        apps = []
        search_dirs = [
            "/usr/share/applications",
            "/var/lib/flatpak/exports/share/applications",
            str(Path.home() / ".local/share/applications"),
            str(Path.home() / ".local/share/flatpak/exports/share/applications"),
        ]
        seen = set()

        for d in search_dirs:
            if not os.path.isdir(d):
                continue
            for f in os.listdir(d):
                if not f.endswith(".desktop") or f in seen:
                    continue
                seen.add(f)
                path = os.path.join(d, f)
                try:
                    app_info = Gio.DesktopAppInfo.new_from_filename(path)
                    if app_info and not app_info.get_nodisplay():
                        apps.append({
                            "name": app_info.get_display_name() or f,
                            "icon": app_info.get_string("Icon") or "application-x-executable",
                            "info": app_info,
                            "type": "app",
                        })
                except Exception:
                    pass

        apps.sort(key=lambda a: a["name"].lower())
        return apps


class PaletteWindow(Adw.ApplicationWindow):
    def __init__(self, apps, **kwargs):
        super().__init__(**kwargs)

        self.apps = apps
        self.set_default_size(640, 420)
        self.set_resizable(False)
        self.set_decorated(False)
        self.set_modal(True)

        # Semi-transparent dark background
        css = Gtk.CssProvider()
        css.load_from_string("""
            window {
                background-color: rgba(22, 22, 22, 0.92);
                border-radius: 16px;
                border: 1px solid rgba(255, 255, 255, 0.06);
            }
            .search-entry {
                background-color: rgba(255, 255, 255, 0.06);
                border: 1px solid rgba(255, 255, 255, 0.08);
                border-radius: 12px;
                color: rgba(255, 255, 255, 0.92);
                font-family: "Geist";
                font-size: 16px;
                padding: 12px 16px;
                min-height: 24px;
            }
            .search-entry:focus {
                border-color: rgba(255, 255, 255, 0.15);
                box-shadow: 0 0 0 2px rgba(255, 255, 255, 0.04);
            }
            .result-row {
                padding: 8px 16px;
                border-radius: 10px;
                color: rgba(255, 255, 255, 0.88);
                font-family: "Geist";
            }
            .result-row:selected {
                background-color: rgba(255, 255, 255, 0.08);
            }
            .result-name {
                font-size: 14px;
                font-weight: 500;
                color: rgba(255, 255, 255, 0.92);
            }
            .result-detail {
                font-size: 12px;
                color: rgba(255, 255, 255, 0.45);
            }
            .ai-response {
                font-family: "Geist";
                font-size: 13px;
                color: rgba(255, 255, 255, 0.80);
                padding: 12px 16px;
            }
            .hint {
                font-size: 11px;
                color: rgba(255, 255, 255, 0.25);
                font-family: "Geist";
            }
        """)
        Gtk.StyleContext.add_provider_for_display(
            self.get_display(), css,
            Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION
        )

        # Layout
        box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=0)
        box.set_margin_top(16)
        box.set_margin_bottom(12)
        box.set_margin_start(16)
        box.set_margin_end(16)
        self.set_content(box)

        # Search entry
        self.entry = Gtk.Entry()
        self.entry.set_placeholder_text("Search apps, files, or ask anything...")
        self.entry.add_css_class("search-entry")
        self.entry.connect("changed", self._on_search_changed)
        self.entry.connect("activate", self._on_activate)
        box.append(self.entry)

        # Scrolled results
        scroll = Gtk.ScrolledWindow()
        scroll.set_vexpand(True)
        scroll.set_margin_top(8)
        scroll.set_min_content_height(280)
        box.append(scroll)

        self.results_box = Gtk.ListBox()
        self.results_box.set_selection_mode(Gtk.SelectionMode.SINGLE)
        self.results_box.add_css_class("boxed-list")
        self.results_box.connect("row-activated", self._on_row_activated)
        scroll.set_child(self.results_box)

        # Hint bar
        hint = Gtk.Label(label="Enter to select  ·  Esc to close  ·  Prefix ? for AI")
        hint.add_css_class("hint")
        hint.set_margin_top(8)
        box.append(hint)

        # Keyboard handling
        key_ctrl = Gtk.EventControllerKey()
        key_ctrl.connect("key-pressed", self._on_key_pressed)
        self.add_controller(key_ctrl)

        # Show all apps initially
        self._show_apps("")

    def _on_key_pressed(self, controller, keyval, keycode, state):
        if keyval == 65307:  # Escape
            self.close()
            return True
        if keyval in (65364, 65362):  # Down/Up arrows
            return False  # Let ListBox handle
        return False

    def _on_search_changed(self, entry):
        query = entry.get_text().strip()

        if query.startswith("?"):
            # AI query mode — don't filter apps, wait for Enter
            self._clear_results()
            row = self._make_hint_row("Press Enter to ask AI: " + query[1:].strip())
            self.results_box.append(row)
        else:
            self._show_apps(query)

    def _show_apps(self, query):
        self._clear_results()
        query_lower = query.lower()

        for app in self.apps:
            if query_lower and query_lower not in app["name"].lower():
                continue
            row = self._make_app_row(app)
            self.results_box.append(row)
            if self.results_box.get_first_child():
                # Limit visible results
                children = []
                child = self.results_box.get_first_child()
                while child:
                    children.append(child)
                    child = child.get_next_sibling()
                if len(children) >= 8:
                    break

        # Select first result
        first = self.results_box.get_row_at_index(0)
        if first:
            self.results_box.select_row(first)

    def _make_app_row(self, app):
        row = Gtk.ListBoxRow()
        row.add_css_class("result-row")
        row.app_data = app

        hbox = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=12)
        hbox.set_margin_top(4)
        hbox.set_margin_bottom(4)

        icon = Gtk.Image.new_from_icon_name(app["icon"])
        icon.set_pixel_size(32)
        hbox.append(icon)

        label = Gtk.Label(label=app["name"])
        label.add_css_class("result-name")
        label.set_halign(Gtk.Align.START)
        hbox.append(label)

        row.set_child(hbox)
        return row

    def _make_hint_row(self, text):
        row = Gtk.ListBoxRow()
        row.add_css_class("result-row")
        row.app_data = {"type": "ai_pending"}
        label = Gtk.Label(label=text)
        label.add_css_class("result-detail")
        label.set_halign(Gtk.Align.START)
        label.set_margin_top(8)
        label.set_margin_bottom(8)
        row.set_child(label)
        return row

    def _make_ai_row(self, text):
        row = Gtk.ListBoxRow()
        row.add_css_class("result-row")
        row.app_data = {"type": "ai_result", "text": text}

        label = Gtk.Label(label=text)
        label.add_css_class("ai-response")
        label.set_halign(Gtk.Align.START)
        label.set_wrap(True)
        label.set_max_width_chars(70)
        label.set_selectable(True)
        row.set_child(label)
        return row

    def _on_activate(self, entry):
        query = entry.get_text().strip()

        if query.startswith("?"):
            # AI query
            ai_query = query[1:].strip()
            if ai_query:
                self._ask_ai(ai_query)
            return

        # Launch selected app
        selected = self.results_box.get_selected_row()
        if selected and hasattr(selected, 'app_data'):
            self._launch(selected.app_data)

    def _on_row_activated(self, listbox, row):
        if hasattr(row, 'app_data'):
            self._launch(row.app_data)

    def _launch(self, app_data):
        if app_data.get("type") == "app" and "info" in app_data:
            try:
                app_data["info"].launch([], None)
                self._audit("APP", "LAUNCH", app_data["name"])
            except Exception as e:
                print(f"Launch failed: {e}")
            self.close()

    def _ask_ai(self, query):
        self._clear_results()
        thinking = self._make_hint_row("thinking...")
        self.results_box.append(thinking)

        def do_query():
            try:
                payload = json.dumps({
                    "model": OLLAMA_MODEL,
                    "messages": [
                        {"role": "system", "content": "You are a helpful assistant for Collet OS. Answer concisely in 2-3 sentences. If the user asks for a command, show it. Detect and respond in the user's language."},
                        {"role": "user", "content": query}
                    ],
                    "temperature": 0.2,
                    "max_tokens": 200
                }).encode()

                req = urllib.request.Request(
                    f"{OLLAMA_HOST}/v1/chat/completions",
                    data=payload,
                    headers={"Content-Type": "application/json"}
                )
                with urllib.request.urlopen(req, timeout=60) as resp:
                    data = json.loads(resp.read())
                    answer = data["choices"][0]["message"]["content"]

                GLib.idle_add(self._show_ai_result, answer)
                self._audit("AI", "PALETTE_QUERY", query)
            except Exception as e:
                GLib.idle_add(self._show_ai_result, f"Error: {e}")

        thread = threading.Thread(target=do_query, daemon=True)
        thread.start()

    def _show_ai_result(self, text):
        self._clear_results()
        row = self._make_ai_row(text)
        self.results_box.append(row)

    def _clear_results(self):
        while True:
            child = self.results_box.get_first_child()
            if child is None:
                break
            self.results_box.remove(child)

    def _audit(self, category, action, detail=""):
        try:
            AUDIT_DIR.mkdir(parents=True, exist_ok=True)
            with open(AUDIT_DIR / "actions.log", "a") as f:
                from datetime import datetime
                f.write(f"{datetime.now().isoformat()} | {category} | {action} | {detail}\n")
        except Exception:
            pass


def main():
    app = ColletPalette()
    app.run(None)


if __name__ == "__main__":
    main()
