#!/usr/bin/env bash
# Collet OS — Audit Logger
# Uses systemd journal. Query with: journalctl -t collet --since today
#
# Usage: collet-audit <category> <action> [detail]
# Categories: AI, FILE, SYSTEM, APP, AUTH, NETWORK
#
# Examples:
#   collet-audit AI ASK_QUERY "check disk usage"
#   collet-audit APP LAUNCH "Chromium"
#   collet-audit FILE SUMMARIZE "/home/user/report.pdf"
#   collet-audit SYSTEM FIRST_BOOT "Collet OS initialized"

CATEGORY="${1:-UNKNOWN}"
ACTION="${2:-unknown}"
DETAIL="${3:-}"

logger -t collet -p user.info "${CATEGORY} | ${ACTION} | ${DETAIL}"
