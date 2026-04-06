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
PLATFORM_ID="platform:f41"
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

echo ":: Branding applied"
