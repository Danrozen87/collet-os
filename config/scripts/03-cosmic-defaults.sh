#!/usr/bin/env bash
set -euo pipefail

# ── Collet OS COSMIC Defaults ─────────────────────────────
# COSMIC stores config as RON (Rust Object Notation) files
# in /etc/cosmic/ (system defaults) and ~/.config/cosmic/ (user).
# System defaults are the baseline; users override in their home.

echo ":: Configuring COSMIC defaults"

COSMIC_SYS="/etc/cosmic"
mkdir -p "$COSMIC_SYS"

# ── Appearance ─────────────────────────────────────────────
mkdir -p "$COSMIC_SYS/com.system76.CosmicTheme.Dark/v1"
mkdir -p "$COSMIC_SYS/com.system76.CosmicTheme.Light/v1"

# Dark theme — Collet Design System neutrals (zero chroma)
cat > "$COSMIC_SYS/com.system76.CosmicTheme.Dark/v1/is_dark" << 'RON'
true
RON

# ── Desktop ────────────────────────────────────────────────
mkdir -p "$COSMIC_SYS/com.system76.CosmicComp/v1"

# Window rounding
cat > "$COSMIC_SYS/com.system76.CosmicComp/v1/active_hint" << 'RON'
1
RON

# ── Panel / Dock ───────────────────────────────────────────
mkdir -p "$COSMIC_SYS/com.system76.CosmicPanel.Dock/v1"

# ── Wallpaper ──────────────────────────────────────────────
mkdir -p "$COSMIC_SYS/com.system76.CosmicBackground/v1"
cat > "$COSMIC_SYS/com.system76.CosmicBackground/v1/all_outputs" << 'RON'
(
    source: Path("/usr/share/backgrounds/collet/default-dark.png"),
    filter_method: Lanczos,
    scaling_mode: Zoom,
    sampling_method: Alphanumeric,
    rotation_frequency: 300,
)
RON

# ── Terminal defaults ──────────────────────────────────────
mkdir -p "$COSMIC_SYS/com.system76.CosmicTerm/v1"

# ── GTK4 theme for Flatpak apps ────────────────────────────
GTK_CSS_SRC="/usr/share/collet-os/gtk-4.0/gtk.css"
GTK_CSS_SYSTEM="/etc/gtk-4.0/gtk.css"
if [ -f "$GTK_CSS_SRC" ]; then
    mkdir -p "$(dirname "$GTK_CSS_SYSTEM")"
    cp "$GTK_CSS_SRC" "$GTK_CSS_SYSTEM"
fi

echo ":: COSMIC defaults applied"
