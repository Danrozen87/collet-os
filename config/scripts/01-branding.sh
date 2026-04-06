#!/usr/bin/env bash
set -euo pipefail

# ── Collet OS Branding ─────────────────────────────────────
# Applied during image build. Overrides Fedora defaults.

echo ":: Applying Collet OS branding"

# os-release
cat > /usr/lib/os-release << 'EOF'
NAME="Collet OS"
VERSION="1.0"
ID=collet-os
ID_LIKE="fedora"
VERSION_ID=1.0
PLATFORM_ID="platform:f42"
PRETTY_NAME="Collet OS 1.0"
VARIANT="Desktop"
VARIANT_ID=desktop
HOME_URL="https://collet-os.eu"
SUPPORT_URL="https://collet-os.eu/support"
BUG_REPORT_URL="https://collet-os.eu/issues"
PRIVACY_POLICY_URL="https://collet-os.eu/privacy"
DEFAULT_HOSTNAME="collet"
EOF

# Symlink for compatibility
ln -sf /usr/lib/os-release /etc/os-release

# Set default hostname
echo "collet" > /etc/hostname

# ── Plymouth boot splash ───────────────────────────────────
# Set Collet as default Plymouth theme
if [ -d /usr/share/plymouth/themes/collet ]; then
    plymouth-set-default-theme collet 2>/dev/null || true
    echo ":: Plymouth theme set"
fi

# ── GDM login screen ──────────────────────────────────────
# Apply glassmorphism CSS to GDM's GNOME Shell theme
GDM_CSS="/usr/share/collet-os/gdm/collet-gdm.css"
GNOME_SHELL_THEME="/usr/share/gnome-shell/theme/gnome-shell.css"
if [ -f "$GDM_CSS" ] && [ -f "$GNOME_SHELL_THEME" ]; then
    # Append Collet login styles to GNOME Shell theme
    cat "$GDM_CSS" >> "$GNOME_SHELL_THEME"
    echo ":: GDM glassmorphism applied"
fi

# ── GDM background ────────────────────────────────────────
# Set the default wallpaper for GDM (shown blurred behind login)
GDM_DCONF="/etc/dconf/db/gdm.d/01-collet-gdm"
mkdir -p /etc/dconf/db/gdm.d
cat > "$GDM_DCONF" << 'GDMCONF'
[org/gnome/desktop/background]
picture-uri='file:///usr/share/backgrounds/collet/default.png'
picture-uri-dark='file:///usr/share/backgrounds/collet/default-dark.png'
picture-options='zoom'

[org/gnome/login-screen]
logo=''
banner-message-enable=false
GDMCONF

# Ensure GDM dconf profile exists
mkdir -p /etc/dconf/profile
cat > /etc/dconf/profile/gdm << 'GDMPROFILE'
user-db:user
system-db:gdm
GDMPROFILE

dconf update 2>/dev/null || true
echo ":: GDM branding configured"

echo ":: Branding applied"
