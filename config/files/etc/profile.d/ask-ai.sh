# Collet OS — Terminal AI Helper
# Provides the `ask` command and `?` shortcut in bash sessions
if command -v ask >/dev/null 2>&1; then
    ?() { ask "$@"; }
fi
