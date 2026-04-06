#!/usr/bin/env bash
set -euo pipefail

# ── Collet OS First Boot ───────────────────────────────────
# Runs once on first user login.
# Sets up Flatpak, fonts, AI config, and COSMIC user defaults.

MARKER="$HOME/.config/collet-os/.first-boot-done"

if [ -f "$MARKER" ]; then
    exit 0
fi

echo ":: Collet OS first boot setup"

# Ensure Flathub is configured
flatpak remote-add --user --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo

# Create user config directories
mkdir -p "$HOME/.config/collet-os/ai"
mkdir -p "$HOME/.local/share/collet-os/conversations"
mkdir -p "$HOME/.local/share/collet-os/audit"
mkdir -p "$HOME/.local/bin"

# Copy default AI backend config
if [ ! -f "$HOME/.config/collet-os/ai/backend.toml" ]; then
    cp /usr/share/collet-os/ai/backend.toml "$HOME/.config/collet-os/ai/backend.toml" 2>/dev/null || true
fi

# Install audit logger
AUDIT_SRC="/usr/share/collet-os/audit/collet-audit.sh"
if [ -f "$AUDIT_SRC" ] && [ ! -f "$HOME/.local/bin/collet-audit" ]; then
    cp "$AUDIT_SRC" "$HOME/.local/bin/collet-audit"
    chmod +x "$HOME/.local/bin/collet-audit"
fi

# Copy Geist fonts to user font directory (fontconfig on immutable OS)
if [ -d "/usr/share/fonts/collet" ] && [ ! -d "$HOME/.local/share/fonts" ]; then
    mkdir -p "$HOME/.local/share/fonts"
    cp /usr/share/fonts/collet/*.ttf "$HOME/.local/share/fonts/" 2>/dev/null || true
    fc-cache -f 2>/dev/null || true
fi

# Install GTK4 theme for Flatpak apps
GTK_CSS="/usr/share/collet-os/gtk-4.0/gtk.css"
if [ -f "$GTK_CSS" ] && [ ! -f "$HOME/.config/gtk-4.0/gtk.css" ]; then
    mkdir -p "$HOME/.config/gtk-4.0"
    cp "$GTK_CSS" "$HOME/.config/gtk-4.0/gtk.css"
fi

# Log first boot
bash /usr/share/collet-os/audit/collet-audit.sh SYSTEM FIRST_BOOT "Collet OS initialized" 2>/dev/null || true

# Mark first boot as done
mkdir -p "$(dirname "$MARKER")"
touch "$MARKER"

echo ":: First boot setup complete"
