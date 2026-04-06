#!/usr/bin/env bash
set -euo pipefail

# ── Collet OS First Boot ───────────────────────────────────
# Runs once on first user login.
# Sets up Flatpak remotes and ensures defaults are applied.

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

# Copy default AI backend config to user space (if not exists)
if [ ! -f "$HOME/.config/collet-os/ai/backend.toml" ]; then
    cp /usr/share/collet-os/ai/backend.toml "$HOME/.config/collet-os/ai/backend.toml"
fi

# Install Nautilus scripts (AI-powered file actions)
SCRIPTS_SRC="/usr/share/collet-os/nautilus-scripts"
SCRIPTS_DST="$HOME/.local/share/nautilus/scripts"
if [ -d "$SCRIPTS_SRC" ] && [ ! -d "$SCRIPTS_DST" ]; then
    mkdir -p "$SCRIPTS_DST"
    cp "$SCRIPTS_SRC"/* "$SCRIPTS_DST/"
    chmod +x "$SCRIPTS_DST"/*
fi

# Install audit logger
AUDIT_SRC="/usr/share/collet-os/audit/collet-audit.sh"
AUDIT_DST="$HOME/.local/bin/collet-audit"
if [ -f "$AUDIT_SRC" ] && [ ! -f "$AUDIT_DST" ]; then
    mkdir -p "$HOME/.local/bin"
    cp "$AUDIT_SRC" "$AUDIT_DST"
    chmod +x "$AUDIT_DST"
fi

# Copy Geist fonts to user font directory (fontconfig on immutable OS)
if [ -d "/usr/share/fonts/collet" ] && [ ! -d "$HOME/.local/share/fonts" ]; then
    mkdir -p "$HOME/.local/share/fonts"
    cp /usr/share/fonts/collet/*.ttf "$HOME/.local/share/fonts/"
    fc-cache -f 2>/dev/null || true
fi

# Install Collet GTK4 theme to user config
GTK_CSS="/usr/share/collet-os/gtk-4.0/gtk.css"
USER_GTK="$HOME/.config/gtk-4.0/gtk.css"
if [ -f "$GTK_CSS" ] && [ ! -f "$USER_GTK" ]; then
    mkdir -p "$(dirname "$USER_GTK")"
    cp "$GTK_CSS" "$USER_GTK"
fi

# Log first boot
bash "$AUDIT_SRC" SYSTEM FIRST_BOOT "Collet OS initialized" 2>/dev/null || true

# Mark first boot as done
mkdir -p "$(dirname "$MARKER")"
touch "$MARKER"

echo ":: First boot setup complete"
