#!/usr/bin/env bash
set -euo pipefail

# ── Collet OS COSMIC System Defaults ──────────────────────
# Written to /usr/share/cosmic/ (read-only system defaults)
# and /etc/cosmic/ (admin overrides).
# User config in ~/.config/cosmic/ takes priority.
# First-boot script ensures user config is set correctly.

echo ":: Configuring COSMIC system defaults"

COSMIC_SHARE="/usr/share/cosmic"

# ── Wallpaper (system default) ─────────────────────────────
mkdir -p "$COSMIC_SHARE/com.system76.CosmicBackground/v1"
cat > "$COSMIC_SHARE/com.system76.CosmicBackground/v1/all" << 'RON'
(
    output: "all",
    source: Path("/usr/share/backgrounds/collet/default-dark.png"),
    filter_by_theme: false,
    rotation_frequency: 3600,
    filter_method: Lanczos,
    scaling_mode: Zoom,
    sampling_method: Alphanumeric,
)
RON
echo "true" > "$COSMIC_SHARE/com.system76.CosmicBackground/v1/same-on-all"
echo "[All]" > "$COSMIC_SHARE/com.system76.CosmicBackground/v1/backgrounds"

# ── Terminal ───────────────────────────────────────────────
mkdir -p "$COSMIC_SHARE/com.system76.CosmicTerm/v1"
echo '"Geist Mono"' > "$COSMIC_SHARE/com.system76.CosmicTerm/v1/font_name"
echo '14' > "$COSMIC_SHARE/com.system76.CosmicTerm/v1/font_size"

# ── Editor ─────────────────────────────────────────────────
mkdir -p "$COSMIC_SHARE/com.system76.CosmicEdit/v1"
echo '"Geist Mono"' > "$COSMIC_SHARE/com.system76.CosmicEdit/v1/font_name"
echo '14' > "$COSMIC_SHARE/com.system76.CosmicEdit/v1/font_size"

# ── GTK4 theme for Flatpak apps ───────────────────────────
GTK_CSS_SRC="/usr/share/collet-os/gtk-4.0/gtk.css"
GTK_CSS_SYSTEM="/etc/gtk-4.0/gtk.css"
if [ -f "$GTK_CSS_SRC" ]; then
    mkdir -p "$(dirname "$GTK_CSS_SYSTEM")"
    cp "$GTK_CSS_SRC" "$GTK_CSS_SYSTEM"
fi

echo ":: COSMIC defaults applied"
