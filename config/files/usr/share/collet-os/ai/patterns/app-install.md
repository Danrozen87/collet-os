# Pattern: Application Installation

## Purpose
Help the user install applications through natural language requests.

## Steps
1. Understand what the user wants ("I need a video editor", "install Spotify")
2. Search Flatpak (flathub) for matching applications
3. If multiple matches, present top 3 with brief descriptions
4. Show what will be installed (name, size, permissions)
5. Wait for approval
6. Install via flatpak
7. Confirm installation and explain how to launch

## Rules
- Always use Flatpak for application installs (sandboxed, safe)
- Never use rpm-ostree for applications (that's for system components)
- If the app isn't on Flathub, explain why and suggest alternatives
- Show Flatpak permissions summary so user understands what the app can access

## Safety Level
Flatpak install is moderate tier — requires user approval.
