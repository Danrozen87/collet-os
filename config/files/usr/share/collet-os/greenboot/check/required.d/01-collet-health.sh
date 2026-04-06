#!/usr/bin/env bash
# Collet OS — Greenboot Health Check
# If any check fails, Greenboot rolls back to the previous deployment.

# Desktop manager must be running
systemctl is-active gdm.service || exit 1

# Network must be reachable
ping -c 1 -W 5 1.1.1.1 > /dev/null 2>&1 || exit 1

# If Ollama is enabled, it must be running
if systemctl is-enabled ollama.service > /dev/null 2>&1; then
    systemctl is-active ollama.service || exit 1
fi

exit 0
