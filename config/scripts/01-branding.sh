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
VERSION_ID=43
PLATFORM_ID="platform:f43"
PRETTY_NAME="Collet OS 1.0 (COSMIC)"
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

# ── Replace default wallpapers ─────────────────────────────
# COSMIC and all DEs look for /usr/share/backgrounds/default*
# Replace the symlinks with our actual files — no config needed
rm -f /usr/share/backgrounds/default-dark.jxl /usr/share/backgrounds/default.jxl 2>/dev/null || true
cp /usr/share/backgrounds/collet/default-dark.png /usr/share/backgrounds/default-dark.jxl 2>/dev/null || true
cp /usr/share/backgrounds/collet/default.png /usr/share/backgrounds/default.jxl 2>/dev/null || true
echo ":: Default wallpapers replaced"

# ── Fix script permissions ─────────────────────────────────
chmod +x /usr/bin/ask 2>/dev/null || true
chmod +x /usr/share/collet-os/first-boot.sh 2>/dev/null || true
chmod +x /usr/share/collet-os/audit/collet-audit.sh 2>/dev/null || true
echo ":: Script permissions fixed"

# ── Plymouth boot splash ───────────────────────────────────
if [ -d /usr/share/plymouth/themes/collet ]; then
    plymouth-set-default-theme collet 2>/dev/null || true
    echo ":: Plymouth theme set"
fi

echo ":: Branding applied"
