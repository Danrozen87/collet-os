#!/usr/bin/env bash
set -euo pipefail

# ── Collet OS Compositor ──────────────────────────────────
# Downloads pre-built cosmic-comp binary from our fork's
# GitHub releases. Built on native ARM64 runner — no
# cross-compilation, no QEMU, fast.
#
# The binary includes:
# - Spring animations on window open/close/tile/minimize
# - Refined softer shadows
# - Workspace spring transitions

echo ":: Installing Collet compositor"

ARCH=$(uname -m)
case "$ARCH" in
    aarch64|arm64) ASSET="cosmic-comp" ;;
    x86_64)        ASSET="cosmic-comp" ;;
    *)             echo ":: Unsupported arch: $ARCH, keeping stock"; exit 0 ;;
esac

# Download from our fork's latest release
DOWNLOAD_URL="https://github.com/Danrozen87/collet-cosmic-comp/releases/latest/download/${ASSET}"

if curl -sfL "$DOWNLOAD_URL" -o /tmp/cosmic-comp-collet; then
    chmod +x /tmp/cosmic-comp-collet
    cp /tmp/cosmic-comp-collet /usr/bin/cosmic-comp
    rm /tmp/cosmic-comp-collet
    echo ":: Collet compositor installed (spring animations + refined shadows)"
else
    echo ":: WARNING: Could not download compositor, keeping stock"
fi
