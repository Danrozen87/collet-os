#!/usr/bin/env bash
set -euo pipefail

# ── Collet OS Compositor ──────────────────────────────────
# Builds our cosmic-comp fork with spring animations and
# refined shadows. Replaces the stock binary in the image.
#
# This runs during the image build (not on user machines).
# The compiled binary is baked into the immutable image.

echo ":: Building Collet compositor (spring animations + shadows)"

# Install build dependencies
dnf install -y --setopt=install_weak_deps=False \
    rust cargo gcc g++ make cmake \
    wayland-devel libxkbcommon-devel \
    mesa-libEGL-devel mesa-libgbm-devel \
    libinput-devel libudev-devel \
    libseat-devel pixman-devel \
    pango-devel cairo-devel \
    systemd-devel dbus-devel \
    pipewire-devel libdisplay-info-devel \
    clang-devel 2>/dev/null || true

# Clone our fork
cd /tmp
git clone --depth 1 https://github.com/Danrozen87/collet-cosmic-comp.git
cd collet-cosmic-comp

# Build with collet-animations feature (enabled by default)
cargo build --release 2>&1 | tail -5

# Replace stock compositor binary
if [ -f target/release/cosmic-comp ]; then
    cp target/release/cosmic-comp /usr/bin/cosmic-comp
    echo ":: Collet compositor installed"
else
    echo ":: WARNING: Compositor build failed, keeping stock"
fi

# Cleanup build artifacts to keep image small
cd /
rm -rf /tmp/collet-cosmic-comp
dnf remove -y rust cargo gcc g++ make cmake clang-devel 2>/dev/null || true
dnf clean all 2>/dev/null || true

echo ":: Compositor step complete"
