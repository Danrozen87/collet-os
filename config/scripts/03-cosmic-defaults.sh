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

# ── Dark Theme — Collet Design System ──────────────────────
# OKLCH neutrals converted to SRGBA for COSMIC
# Dark: zero chroma, pure greys (oklch 0.145-0.250, 0 chroma)
# Semantic: desaturated intent colors
cat > "$COSMIC_SYS/com.system76.CosmicTheme.Dark/v1/is_dark" << 'RON'
true
RON

# Background: oklch(0.145 0.000 0.0) ≈ #252525
cat > "$COSMIC_SYS/com.system76.CosmicTheme.Dark/v1/bg_color" << 'RON'
(0.145, 0.145, 0.145, 1.0)
RON

# Surface: oklch(0.185 0.000 0.0) ≈ #2f2f2f
cat > "$COSMIC_SYS/com.system76.CosmicTheme.Dark/v1/primary_container_bg" << 'RON'
(0.184, 0.184, 0.184, 1.0)
RON

# Text: oklch(0.880 0.000 0.0) ≈ #e0e0e0
cat > "$COSMIC_SYS/com.system76.CosmicTheme.Dark/v1/on_bg_color" << 'RON'
(0.878, 0.878, 0.878, 1.0)
RON

# ── Light Theme — Collet Design System ─────────────────────
# Light: warm muted tones (oklch hue 90, chroma 0.003-0.005)
cat > "$COSMIC_SYS/com.system76.CosmicTheme.Light/v1/is_dark" << 'RON'
false
RON

# Background: oklch(0.955 0.005 90.0) ≈ #f2f1ee
cat > "$COSMIC_SYS/com.system76.CosmicTheme.Light/v1/bg_color" << 'RON'
(0.949, 0.945, 0.933, 1.0)
RON

# Text: oklch(0.270 0.003 90.0) ≈ #454340
cat > "$COSMIC_SYS/com.system76.CosmicTheme.Light/v1/on_bg_color" << 'RON'
(0.271, 0.263, 0.251, 1.0)
RON

# ── Compositor ─────────────────────────────────────────────
mkdir -p "$COSMIC_SYS/com.system76.CosmicComp/v1"

# Window gap and active hint
cat > "$COSMIC_SYS/com.system76.CosmicComp/v1/active_hint" << 'RON'
2
RON

# Border radius
cat > "$COSMIC_SYS/com.system76.CosmicComp/v1/border_radius" << 'RON'
12
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

# Font family
cat > "$COSMIC_SYS/com.system76.CosmicTerm/v1/font_name" << 'RON'
"Geist Mono"
RON

# Font size
cat > "$COSMIC_SYS/com.system76.CosmicTerm/v1/font_size" << 'RON'
14
RON

# ── Text Editor defaults ──────────────────────────────────
mkdir -p "$COSMIC_SYS/com.system76.CosmicEdit/v1"

cat > "$COSMIC_SYS/com.system76.CosmicEdit/v1/font_name" << 'RON'
"Geist Mono"
RON

cat > "$COSMIC_SYS/com.system76.CosmicEdit/v1/font_size" << 'RON'
14
RON

# ── GTK4 theme for Flatpak apps ────────────────────────────
GTK_CSS_SRC="/usr/share/collet-os/gtk-4.0/gtk.css"
GTK_CSS_SYSTEM="/etc/gtk-4.0/gtk.css"
if [ -f "$GTK_CSS_SRC" ]; then
    mkdir -p "$(dirname "$GTK_CSS_SYSTEM")"
    cp "$GTK_CSS_SRC" "$GTK_CSS_SYSTEM"
fi

echo ":: COSMIC defaults applied"
