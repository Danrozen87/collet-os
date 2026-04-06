#!/usr/bin/env bash
set -euo pipefail

# ── Collet OS GNOME Defaults ──────────────────────────────
# Compile dconf overrides into the system database.
# These provide sane defaults; users can override everything.

echo ":: Compiling GNOME defaults"

# Compile dconf database
dconf update

# Compile GSettings schemas (if any custom schemas were added)
if [ -d /usr/share/glib-2.0/schemas ]; then
    glib-compile-schemas /usr/share/glib-2.0/schemas
fi

# ── Collet GTK4 Theme ──────────────────────────────────────
# Install system-wide GTK4 CSS override.
# This file defines the visual identity of every GTK4/libadwaita app.
GTK_CSS_SRC="/usr/share/collet-os/gtk-4.0/gtk.css"
GTK_CSS_SYSTEM="/etc/gtk-4.0/gtk.css"
if [ -f "$GTK_CSS_SRC" ]; then
    mkdir -p "$(dirname "$GTK_CSS_SYSTEM")"
    cp "$GTK_CSS_SRC" "$GTK_CSS_SYSTEM"
    echo ":: Collet GTK4 theme installed"
fi

echo ":: GNOME defaults applied"
