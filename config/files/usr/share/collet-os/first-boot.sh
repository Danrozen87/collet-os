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

# Mark first boot as done
mkdir -p "$(dirname "$MARKER")"
touch "$MARKER"

echo ":: First boot setup complete"
