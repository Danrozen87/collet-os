# Pattern: System Health Check

## Purpose
Provide a clear, at-a-glance summary of system health when the user asks "how is my computer doing?" or similar.

## Steps
1. Check disk usage (df -h)
2. Check RAM usage (free -h)
3. Check CPU load (uptime)
4. Check system temperature if available (sensors)
5. Check battery status if applicable (upower)
6. Check pending updates (rpm-ostree status, flatpak remote-ls --updates)
7. Check running services health (systemctl --failed)

## Output Format
Present as a simple status summary:
- Use plain language, not raw numbers
- "Your disk is 45% full — plenty of space" not "45% used of 460GB"
- Flag anything that needs attention
- Suggest actions only if something is actually wrong

## Safety Level
All commands are read-only (safe tier). No approval needed.
