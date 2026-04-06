#!/usr/bin/env bash
# Collet OS — Audit Logger
# Unified audit trail for AI actions and user system actions.
# Called by: ask command, nautilus scripts, first-boot, and systemd hooks.
#
# Usage: collet-audit <category> <action> [detail]
# Categories: AI, FILE, SYSTEM, APP, AUTH
#
# Log format: ISO8601 | CATEGORY | ACTION | DETAIL
# Location: ~/.local/share/collet-os/audit/actions.log

set -euo pipefail

AUDIT_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/collet-os/audit"
AUDIT_FILE="$AUDIT_DIR/actions.log"
MAX_SIZE=10485760  # 10MB — rotate when exceeded

mkdir -p "$AUDIT_DIR"

# Rotate if log exceeds max size
if [[ -f "$AUDIT_FILE" ]] && [[ $(stat --printf='%s' "$AUDIT_FILE" 2>/dev/null || echo 0) -gt $MAX_SIZE ]]; then
    mv "$AUDIT_FILE" "$AUDIT_FILE.$(date +%Y%m%d_%H%M%S)"
    # Keep only last 5 rotated logs
    ls -t "$AUDIT_DIR"/actions.log.* 2>/dev/null | tail -n +6 | xargs rm -f 2>/dev/null || true
fi

CATEGORY="${1:-UNKNOWN}"
ACTION="${2:-unknown}"
DETAIL="${3:-}"

printf '%s | %s | %s | %s\n' "$(date -Iseconds)" "$CATEGORY" "$ACTION" "$DETAIL" >> "$AUDIT_FILE"
