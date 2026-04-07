#!/usr/bin/env bash
set -euo pipefail

# ── Collet OS First Boot ───────────────────────────────────
# Runs ONCE per user on first login via systemd user service.
# Applies the complete Collet OS identity: theme, fonts, icons,
# wallpaper, AI config. Idempotent — safe to run multiple times.

MARKER="$HOME/.config/collet-os/.first-boot-done"
[[ -f "$MARKER" ]] && exit 0

echo ":: Collet OS first boot — applying identity"

# ── 1. Fonts ───────────────────────────────────────────────
if [ -d "/usr/share/fonts/collet" ]; then
    mkdir -p "$HOME/.local/share/fonts"
    cp -n /usr/share/fonts/collet/*.ttf "$HOME/.local/share/fonts/" 2>/dev/null || true
    fc-cache -f 2>/dev/null || true
fi

# ── 2. Icons ───────────────────────────────────────────────
if [ -d "/usr/share/icons/WhiteSur" ]; then
    mkdir -p "$HOME/.local/share/icons"
    ln -sf /usr/share/icons/WhiteSur "$HOME/.local/share/icons/WhiteSur" 2>/dev/null || true
fi

# ── 3. COSMIC Toolkit: Geist font + WhiteSur icons ────────
COSMIC_TK="$HOME/.config/cosmic/com.system76.CosmicTk/v1"
mkdir -p "$COSMIC_TK"
echo '(family:"Geist",weight:Normal,stretch:Normal,style:Normal)' > "$COSMIC_TK/interface_font"
echo '(family:"Geist Mono",weight:Normal,stretch:Normal,style:Normal)' > "$COSMIC_TK/monospace_font"
echo '"WhiteSur"' > "$COSMIC_TK/icon_theme"
echo 'true' > "$COSMIC_TK/apply_theme_global"
echo 'Compact' > "$COSMIC_TK/header_size"

# ── 4. COSMIC Dark Theme (Collet Design System) ───────────
# Write to ThemeBuilder — COSMIC watches these via inotify
# and regenerates the derived theme automatically.
DARK="$HOME/.config/cosmic/com.system76.CosmicTheme.Dark.Builder/v1"
mkdir -p "$DARK"

# Palette: zero-chroma neutrals from Collet Design System
cat > "$DARK/palette" << 'RON'
Dark((
    name: "collet-dark",
    bright_red: (red: 0.769, green: 0.361, blue: 0.361, alpha: 1.0),
    bright_green: (red: 0.361, green: 0.675, blue: 0.361, alpha: 1.0),
    bright_orange: (red: 0.769, green: 0.627, blue: 0.314, alpha: 1.0),
    gray_1: (red: 0.145, green: 0.145, blue: 0.145, alpha: 1.0),
    gray_2: (red: 0.184, green: 0.184, blue: 0.184, alpha: 1.0),
    neutral_0: (red: 0.0, green: 0.0, blue: 0.0, alpha: 1.0),
    neutral_1: (red: 0.050, green: 0.050, blue: 0.050, alpha: 1.0),
    neutral_2: (red: 0.100, green: 0.100, blue: 0.100, alpha: 1.0),
    neutral_3: (red: 0.145, green: 0.145, blue: 0.145, alpha: 1.0),
    neutral_4: (red: 0.216, green: 0.216, blue: 0.216, alpha: 1.0),
    neutral_5: (red: 0.290, green: 0.290, blue: 0.290, alpha: 1.0),
    neutral_6: (red: 0.388, green: 0.388, blue: 0.388, alpha: 1.0),
    neutral_7: (red: 0.502, green: 0.502, blue: 0.502, alpha: 1.0),
    neutral_8: (red: 0.678, green: 0.678, blue: 0.678, alpha: 1.0),
    neutral_9: (red: 0.820, green: 0.820, blue: 0.820, alpha: 1.0),
    neutral_10: (red: 0.880, green: 0.880, blue: 0.880, alpha: 1.0),
    accent_blue: (red: 0.502, green: 0.502, blue: 0.502, alpha: 1.0),
    accent_indigo: (red: 0.502, green: 0.502, blue: 0.502, alpha: 1.0),
    accent_purple: (red: 0.502, green: 0.502, blue: 0.502, alpha: 1.0),
    accent_pink: (red: 0.502, green: 0.502, blue: 0.502, alpha: 1.0),
    accent_red: (red: 0.502, green: 0.502, blue: 0.502, alpha: 1.0),
    accent_orange: (red: 0.502, green: 0.502, blue: 0.502, alpha: 1.0),
    accent_yellow: (red: 0.502, green: 0.502, blue: 0.502, alpha: 1.0),
    accent_green: (red: 0.502, green: 0.502, blue: 0.502, alpha: 1.0),
    accent_warm_grey: (red: 0.502, green: 0.502, blue: 0.502, alpha: 1.0),
    ext_warm_grey: (red: 0.502, green: 0.502, blue: 0.502, alpha: 1.0),
    ext_orange: (red: 0.769, green: 0.627, blue: 0.314, alpha: 1.0),
    ext_yellow: (red: 0.769, green: 0.627, blue: 0.314, alpha: 1.0),
    ext_blue: (red: 0.361, green: 0.549, blue: 0.722, alpha: 1.0),
    ext_purple: (red: 0.502, green: 0.502, blue: 0.502, alpha: 1.0),
    ext_pink: (red: 0.502, green: 0.502, blue: 0.502, alpha: 1.0),
    ext_indigo: (red: 0.361, green: 0.549, blue: 0.722, alpha: 1.0),
))
RON

# Background color override
echo 'Some((red:0.145,green:0.145,blue:0.145,alpha:1.0))' > "$DARK/bg_color"

# Accent: neutral grey
echo 'Some((red:0.502,green:0.502,blue:0.502))' > "$DARK/accent"

# Semantic colors
echo 'Some((red:0.769,green:0.361,blue:0.361))' > "$DARK/destructive"
echo 'Some((red:0.361,green:0.675,blue:0.361))' > "$DARK/success"
echo 'Some((red:0.769,green:0.627,blue:0.314))' > "$DARK/warning"

# Corner radii (12px default)
echo '(radius_0:[0.0,0.0,0.0,0.0],radius_xs:[4.0,4.0,4.0,4.0],radius_s:[8.0,8.0,8.0,8.0],radius_m:[12.0,12.0,12.0,12.0],radius_l:[16.0,16.0,16.0,16.0],radius_xl:[160.0,160.0,160.0,160.0])' > "$DARK/corner_radii"

# Window gaps and hints
echo '(0, 4)' > "$DARK/gaps"
echo '0' > "$DARK/active_hint"
echo 'false' > "$DARK/is_frosted"

# ── 5. COSMIC Light Theme ─────────────────────────────────
LIGHT="$HOME/.config/cosmic/com.system76.CosmicTheme.Light.Builder/v1"
mkdir -p "$LIGHT"

cat > "$LIGHT/palette" << 'RON'
Light((
    name: "collet-light",
    bright_red: (red: 0.663, green: 0.314, blue: 0.314, alpha: 1.0),
    bright_green: (red: 0.314, green: 0.584, blue: 0.314, alpha: 1.0),
    bright_orange: (red: 0.682, green: 0.549, blue: 0.251, alpha: 1.0),
    gray_1: (red: 0.949, green: 0.945, blue: 0.933, alpha: 1.0),
    gray_2: (red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0),
    neutral_0: (red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0),
    neutral_1: (red: 0.960, green: 0.957, blue: 0.949, alpha: 1.0),
    neutral_2: (red: 0.920, green: 0.916, blue: 0.906, alpha: 1.0),
    neutral_3: (red: 0.870, green: 0.867, blue: 0.855, alpha: 1.0),
    neutral_4: (red: 0.780, green: 0.776, blue: 0.765, alpha: 1.0),
    neutral_5: (red: 0.678, green: 0.675, blue: 0.663, alpha: 1.0),
    neutral_6: (red: 0.569, green: 0.561, blue: 0.549, alpha: 1.0),
    neutral_7: (red: 0.420, green: 0.412, blue: 0.400, alpha: 1.0),
    neutral_8: (red: 0.353, green: 0.345, blue: 0.333, alpha: 1.0),
    neutral_9: (red: 0.271, green: 0.263, blue: 0.251, alpha: 1.0),
    neutral_10: (red: 0.145, green: 0.141, blue: 0.133, alpha: 1.0),
    accent_blue: (red: 0.353, green: 0.345, blue: 0.333, alpha: 1.0),
    accent_indigo: (red: 0.353, green: 0.345, blue: 0.333, alpha: 1.0),
    accent_purple: (red: 0.353, green: 0.345, blue: 0.333, alpha: 1.0),
    accent_pink: (red: 0.353, green: 0.345, blue: 0.333, alpha: 1.0),
    accent_red: (red: 0.353, green: 0.345, blue: 0.333, alpha: 1.0),
    accent_orange: (red: 0.353, green: 0.345, blue: 0.333, alpha: 1.0),
    accent_yellow: (red: 0.353, green: 0.345, blue: 0.333, alpha: 1.0),
    accent_green: (red: 0.353, green: 0.345, blue: 0.333, alpha: 1.0),
    accent_warm_grey: (red: 0.353, green: 0.345, blue: 0.333, alpha: 1.0),
    ext_warm_grey: (red: 0.502, green: 0.502, blue: 0.502, alpha: 1.0),
    ext_orange: (red: 0.682, green: 0.549, blue: 0.251, alpha: 1.0),
    ext_yellow: (red: 0.682, green: 0.549, blue: 0.251, alpha: 1.0),
    ext_blue: (red: 0.314, green: 0.478, blue: 0.643, alpha: 1.0),
    ext_purple: (red: 0.502, green: 0.502, blue: 0.502, alpha: 1.0),
    ext_pink: (red: 0.502, green: 0.502, blue: 0.502, alpha: 1.0),
    ext_indigo: (red: 0.314, green: 0.478, blue: 0.643, alpha: 1.0),
))
RON

echo 'Some((red:0.949,green:0.945,blue:0.933,alpha:1.0))' > "$LIGHT/bg_color"
echo 'Some((red:0.353,green:0.345,blue:0.333))' > "$LIGHT/accent"
echo 'Some((red:0.663,green:0.314,blue:0.314))' > "$LIGHT/destructive"
echo 'Some((red:0.314,green:0.584,blue:0.314))' > "$LIGHT/success"
echo 'Some((red:0.682,green:0.549,blue:0.251))' > "$LIGHT/warning"
echo '(radius_0:[0.0,0.0,0.0,0.0],radius_xs:[4.0,4.0,4.0,4.0],radius_s:[8.0,8.0,8.0,8.0],radius_m:[12.0,12.0,12.0,12.0],radius_l:[16.0,16.0,16.0,16.0],radius_xl:[160.0,160.0,160.0,160.0])' > "$LIGHT/corner_radii"
echo '(0, 4)' > "$LIGHT/gaps"
echo '0' > "$LIGHT/active_hint"
echo 'false' > "$LIGHT/is_frosted"

# ── 6. Dark mode default ──────────────────────────────────
mkdir -p "$HOME/.config/cosmic/com.system76.CosmicTheme.Mode/v1"
echo 'true' > "$HOME/.config/cosmic/com.system76.CosmicTheme.Mode/v1/is_dark"

# ── 7. Wallpaper — clear any greeter state ────────────────
COSMIC_BG="$HOME/.config/cosmic/com.system76.CosmicBackground/v1"
COSMIC_BG_STATE="$HOME/.local/state/cosmic/com.system76.CosmicBackground/v1"
mkdir -p "$COSMIC_BG" "$COSMIC_BG_STATE"

cat > "$COSMIC_BG/all" << 'RON'
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
echo 'true' > "$COSMIC_BG/same-on-all"
echo '[All]' > "$COSMIC_BG/backgrounds"
rm -f "$COSMIC_BG_STATE/wallpapers" 2>/dev/null || true

# ── 8. Terminal + Editor fonts ────────────────────────────
mkdir -p "$HOME/.config/cosmic/com.system76.CosmicTerm/v1"
echo '"Geist Mono"' > "$HOME/.config/cosmic/com.system76.CosmicTerm/v1/font_name"
echo '14' > "$HOME/.config/cosmic/com.system76.CosmicTerm/v1/font_size"

mkdir -p "$HOME/.config/cosmic/com.system76.CosmicEdit/v1"
echo '"Geist Mono"' > "$HOME/.config/cosmic/com.system76.CosmicEdit/v1/font_name"
echo '14' > "$HOME/.config/cosmic/com.system76.CosmicEdit/v1/font_size"

# ── 9. GTK4/GTK3 for Flatpak apps ────────────────────────
mkdir -p "$HOME/.config/gtk-4.0" "$HOME/.config/gtk-3.0"
cat > "$HOME/.config/gtk-4.0/settings.ini" << 'INI'
[Settings]
gtk-icon-theme-name=WhiteSur
gtk-font-name=Geist 11
INI
cp "$HOME/.config/gtk-4.0/settings.ini" "$HOME/.config/gtk-3.0/settings.ini"

if [ -f "/usr/share/collet-os/gtk-4.0/gtk.css" ]; then
    cp /usr/share/collet-os/gtk-4.0/gtk.css "$HOME/.config/gtk-4.0/gtk.css"
fi

# ── 10. AI config ─────────────────────────────────────────
mkdir -p "$HOME/.config/collet-os/ai"
if [ -f "/usr/share/collet-os/ai/backend.toml" ]; then
    cp -n /usr/share/collet-os/ai/backend.toml "$HOME/.config/collet-os/ai/backend.toml" 2>/dev/null || true
fi
# Default to English
echo "en" > "$HOME/.config/collet-os/ai/language"

# ── 11. Delete any conflicting derived theme ──────────────
# Forces COSMIC to regenerate from our Builder on next login
rm -rf "$HOME/.config/cosmic/com.system76.CosmicTheme.Dark/v1" 2>/dev/null || true
rm -rf "$HOME/.config/cosmic/com.system76.CosmicTheme.Light/v1" 2>/dev/null || true

# ── 12. Dock configuration — single dock, no top panel ────
# Disable top panel, keep only dock at bottom
PANEL_CFG="$HOME/.config/cosmic/com.system76.CosmicPanel/v1"
mkdir -p "$PANEL_CFG"

# Only one panel entry: the dock
echo '["Dock"]' > "$PANEL_CFG/entries"

# Dock config: compact, centered, subtle
DOCK_CFG="$HOME/.config/cosmic/com.system76.CosmicPanel.Dock/v1"
mkdir -p "$DOCK_CFG"
echo '"Dock"' > "$DOCK_CFG/name"
echo 'Bottom' > "$DOCK_CFG/anchor"
echo 'false' > "$DOCK_CFG/anchor_gap"
echo 'M' > "$DOCK_CFG/size"
echo '0.85' > "$DOCK_CFG/opacity"
echo '16' > "$DOCK_CFG/border_radius"
echo '4' > "$DOCK_CFG/padding"
echo '4' > "$DOCK_CFG/spacing"
echo '4' > "$DOCK_CFG/margin"
echo 'false' > "$DOCK_CFG/expand_to_edges"
echo 'false' > "$DOCK_CFG/exclusive_zone"
echo 'ThemeDefault' > "$DOCK_CFG/background"

# ── 13. Log and mark done ─────────────────────────────────
logger -t collet -p user.info "SYSTEM | FIRST_BOOT | Collet OS initialized for $(whoami)"
mkdir -p "$(dirname "$MARKER")"
touch "$MARKER"

echo ":: Collet OS identity applied — log out and back in"
