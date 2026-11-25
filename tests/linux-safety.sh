#!/usr/bin/env bash
# Isolated fixture: never touches the actual home, user service or npm.
set -euo pipefail
repo="$(cd "$(dirname "$0")/.." && pwd)"
fixture="$(mktemp -d)"
trap 'rm -rf -- "$fixture"' EXIT
export HOME="$fixture/home"
mkdir -p "$HOME/.config/sleev" "$HOME/.local/share/sleev" "$HOME/.config/chromium/Default/IndexedDB/not-sleev.ai"
mkdir -p "$fixture/outside" "$fixture/bin"
touch "$HOME/.config/sleev/keep" "$HOME/.local/share/sleev/session" "$HOME/.config/chromium/Default/IndexedDB/not-sleev.ai/keep" "$fixture/outside/keep"
# Restrict dependencies to the real filesystem utilities, with controlled service
# and package commands. The test cannot access a real user systemd instance.
for cmd in bash realpath rm df ln mkdir touch; do ln -s "$(command -v "$cmd")" "$fixture/bin/$cmd"; done
export PATH="$fixture/bin"
# Dry-run preserves data; cleanup removes only owned locations.
bash "$repo/uninstall-sleev.sh" --dry-run >/dev/null
[[ -f "$HOME/.config/sleev/keep" ]]
bash "$repo/uninstall-sleev.sh" --yes >/dev/null
[[ ! -e "$HOME/.config/sleev" && ! -e "$HOME/.local/share/sleev" ]]
[[ -f "$HOME/.config/chromium/Default/IndexedDB/not-sleev.ai/keep" ]]
# An ancestor symlink must never redirect cleanup outside HOME.
rm -rf -- "$HOME/.local"
ln -s "$fixture/outside" "$HOME/.local"
# Make the destination of the would-be removal nonempty.
# Use an absolute utility path: PATH is intentionally restricted.
mkdir -p "$fixture/outside/share/sleev"
touch "$fixture/outside/share/sleev/keep"
if bash "$repo/uninstall-sleev.sh" --yes >/dev/null 2>&1; then
  printf 'FAIL: unsafe ancestor should report incomplete cleanup\n' >&2
  exit 1
fi
[[ -f "$fixture/outside/share/sleev/keep" ]]
[[ -f "$fixture/outside/keep" ]]
printf 'PASS: dry run, scoped cleanup and symlink ancestor refusal\n'
