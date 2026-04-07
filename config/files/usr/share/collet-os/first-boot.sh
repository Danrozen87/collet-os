#!/usr/bin/env bash
set -euo pipefail

# ── Collet OS First Boot ───────────────────────────────────
# Runs once per user on first login.
# Applies ALL Collet OS defaults globally for the logged-in user.
# This must be idempotent and cover every customization.

MARKER="$HOME/.config/collet-os/.first-boot-done"
[[ -f "$MARKER" ]] && exit 0

echo ":: Collet OS first boot setup"

# ── 1. Flatpak ─────────────────────────────────────────────
flatpak remote-add --user --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo 2>/dev/null || true

# ── 2. Fonts (Geist) ──────────────────────────────────────
if [ -d "/usr/share/fonts/collet" ]; then
    mkdir -p "$HOME/.local/share/fonts"
    cp -n /usr/share/fonts/collet/*.ttf "$HOME/.local/share/fonts/" 2>/dev/null || true
    fc-cache -f 2>/dev/null || true
fi

# ── 3. Icons (WhiteSur) ───────────────────────────────────
if [ -d "/usr/share/icons/WhiteSur" ]; then
    mkdir -p "$HOME/.local/share/icons"
    ln -sf /usr/share/icons/WhiteSur "$HOME/.local/share/icons/WhiteSur" 2>/dev/null || true
fi

# ── 4. GTK4/GTK3 settings (icons + fonts for Flatpak apps)
mkdir -p "$HOME/.config/gtk-4.0" "$HOME/.config/gtk-3.0"
cat > "$HOME/.config/gtk-4.0/settings.ini" << 'INI'
[Settings]
gtk-icon-theme-name=WhiteSur
gtk-font-name=Geist 11
INI
cp "$HOME/.config/gtk-4.0/settings.ini" "$HOME/.config/gtk-3.0/settings.ini"

# ── 5. GTK4 CSS theme (spring animations, scrollbars) ─────
if [ -f "/usr/share/collet-os/gtk-4.0/gtk.css" ]; then
    cp /usr/share/collet-os/gtk-4.0/gtk.css "$HOME/.config/gtk-4.0/gtk.css"
fi

# ── 6. COSMIC wallpaper ───────────────────────────────────
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
echo "true" > "$COSMIC_BG/same-on-all"
echo "[All]" > "$COSMIC_BG/backgrounds"

# Clear any greeter-set wallpaper state
rm -f "$COSMIC_BG_STATE/wallpapers" 2>/dev/null || true

# ── 7. COSMIC terminal font ───────────────────────────────
mkdir -p "$HOME/.config/cosmic/com.system76.CosmicTerm/v1"
echo '"Geist Mono"' > "$HOME/.config/cosmic/com.system76.CosmicTerm/v1/font_name"
echo '14' > "$HOME/.config/cosmic/com.system76.CosmicTerm/v1/font_size"

# ── 8. COSMIC editor font ─────────────────────────────────
mkdir -p "$HOME/.config/cosmic/com.system76.CosmicEdit/v1"
echo '"Geist Mono"' > "$HOME/.config/cosmic/com.system76.CosmicEdit/v1/font_name"
echo '14' > "$HOME/.config/cosmic/com.system76.CosmicEdit/v1/font_size"

# ── 9. AI config ──────────────────────────────────────────
mkdir -p "$HOME/.config/collet-os/ai"
mkdir -p "$HOME/.local/share/collet-os/audit"
if [ -f "/usr/share/collet-os/ai/backend.toml" ]; then
    cp -n /usr/share/collet-os/ai/backend.toml "$HOME/.config/collet-os/ai/backend.toml" 2>/dev/null || true
fi

# ── 10. Audit logger ──────────────────────────────────────
if [ -f "/usr/share/collet-os/audit/collet-audit.sh" ]; then
    mkdir -p "$HOME/.local/bin"
    cp /usr/share/collet-os/audit/collet-audit.sh "$HOME/.local/bin/collet-audit"
    chmod +x "$HOME/.local/bin/collet-audit"
fi

# ── 11. Log first boot ────────────────────────────────────
logger -t collet -p user.info "SYSTEM | FIRST_BOOT | Collet OS initialized for $(whoami)"

# ── 12. Mark done ──────────────────────────────────────────
mkdir -p "$(dirname "$MARKER")"
touch "$MARKER"

echo ":: First boot setup complete"
