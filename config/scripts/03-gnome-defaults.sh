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

echo ":: GNOME defaults applied"
