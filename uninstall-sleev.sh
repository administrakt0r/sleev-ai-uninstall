#!/usr/bin/env bash
set -euo pipefail

HOME_DIR="${HOME:?HOME must be set}"
DRY_RUN=0
ASSUME_YES=0

usage() {
  printf 'Usage: %s [--dry-run] [--yes]\n' "$0"
  printf '  --dry-run  Show cleanup targets without changing anything (default behavior is confirmation first).\n'
  printf '  --yes      Skip the interactive confirmation.\n'
}

while (($#)); do
  case "$1" in
    --dry-run) DRY_RUN=1 ;;
    --yes) ASSUME_YES=1 ;;
    -h|--help) usage; exit 0 ;;
    *) printf 'Unknown option: %s\n' "$1" >&2; usage >&2; exit 2 ;;
  esac
  shift
done

if [[ "$DRY_RUN" -eq 0 && "$ASSUME_YES" -eq 0 ]]; then
  if [[ ! -t 0 ]]; then
    printf 'Refusing non-interactive cleanup without --yes. Use --dry-run to inspect targets.\n' >&2
    exit 2
  fi
fi

printf 'Sleev cleanup targets on %s\n' "$HOME_DIR"
printf '%s\n' \
  "$HOME_DIR/.local/bin/sleev" \
  "$HOME_DIR/.config/systemd/user/sleeve-gateway.service" \
  "$HOME_DIR/.config/systemd/user/default.target.wants/sleeve-gateway.service" \
  "$HOME_DIR/.config/sleev" \
  "$HOME_DIR/.local/share/sleev" \
  "$HOME_DIR/.local/state/sleev" \
  "$HOME_DIR/.cache/sleev-gateway"

BROWSER_ROOTS=(
  "$HOME_DIR/.config/google-chrome"
  "$HOME_DIR/.config/chromium"
  "$HOME_DIR/.config/BraveSoftware/Brave-Browser"
  "$HOME_DIR/.var/app/org.chromium.Chromium/config/chromium"
  "$HOME_DIR/.var/app/com.google.Chrome/config/google-chrome"
  "$HOME_DIR/.var/app/com.brave.Browser/config/BraveSoftware/Brave-Browser"
  "$HOME_DIR/.mozilla/firefox"
)

for root in "${BROWSER_ROOTS[@]}"; do
  if [[ -d "$root" ]]; then
    while IFS= read -r -d '' target; do
      printf 'Browser Sleev-named data: %s\n' "$target"
    done < <(find "$root" -depth -iname '*sleev*' -print0 2>/dev/null)
  fi
done

if [[ "$DRY_RUN" -eq 1 ]]; then
  printf '\nDry run only; no changes made.\n'
  exit 0
fi

for browser in chrome google-chrome chromium chromium-browser brave brave-browser firefox; do
  if pgrep -x "$browser" >/dev/null 2>&1; then
    printf 'Close %s before cleanup; no changes have been made.\n' "$browser" >&2
    exit 3
  fi
done

if [[ "$ASSUME_YES" -eq 0 ]]; then
  printf '\nThis permanently deletes Sleev binaries, settings, credentials/tokens, session database, logs, cache, and matching browser site data. No backup will be made.\n'
  read -r -p 'Type REMOVE SLEEV to continue: ' answer
  [[ "$answer" == 'REMOVE SLEEV' ]] || { printf 'Cancelled.\n'; exit 1; }
fi

if command -v systemctl >/dev/null 2>&1; then
  systemctl --user disable --now sleeve-gateway.service >/dev/null 2>&1 || true
fi

remove_home_path() {
  local target="$1"
  case "$target" in
    "$HOME_DIR"/*) ;;
    *) printf 'Refusing path outside home: %s\n' "$target" >&2; return 1 ;;
  esac
  if [[ -e "$target" || -L "$target" ]]; then
    rm -rf -- "$target"
    printf 'Removed %s\n' "$target"
  fi
}

remove_home_path "$HOME_DIR/.config/systemd/user/default.target.wants/sleeve-gateway.service"
remove_home_path "$HOME_DIR/.config/systemd/user/sleeve-gateway.service"
remove_home_path "$HOME_DIR/.local/bin/sleev"
remove_home_path "$HOME_DIR/.config/sleev"
remove_home_path "$HOME_DIR/.local/share/sleev"
remove_home_path "$HOME_DIR/.local/state/sleev"
remove_home_path "$HOME_DIR/.cache/sleev-gateway"

for root in "${BROWSER_ROOTS[@]}"; do
  if [[ -d "$root" ]]; then
    while IFS= read -r -d '' target; do
      remove_home_path "$target"
    done < <(find "$root" -depth -iname '*sleev*' -print0 2>/dev/null)
  fi
done

if command -v systemctl >/dev/null 2>&1; then
  systemctl --user daemon-reload >/dev/null 2>&1 || true
  systemctl --user reset-failed sleeve-gateway.service >/dev/null 2>&1 || true
fi

printf '\nVerification of primary locations:\n'
remaining=0
for target in \
  "$HOME_DIR/.local/bin/sleev" \
  "$HOME_DIR/.config/systemd/user/sleeve-gateway.service" \
  "$HOME_DIR/.config/systemd/user/default.target.wants/sleeve-gateway.service" \
  "$HOME_DIR/.config/sleev" \
  "$HOME_DIR/.local/share/sleev" \
  "$HOME_DIR/.local/state/sleev" \
  "$HOME_DIR/.cache/sleev-gateway"; do
  if [[ -e "$target" || -L "$target" ]]; then
    printf 'STILL EXISTS: %s\n' "$target"
    remaining=1
  fi
done

for root in "${BROWSER_ROOTS[@]}"; do
  if [[ -d "$root" ]]; then
    while IFS= read -r -d '' target; do
      printf 'STILL EXISTS: %s\n' "$target"
      remaining=1
    done < <(find "$root" -depth -iname '*sleev*' -print0 2>/dev/null)
  fi
done

if command -v systemctl >/dev/null 2>&1 && systemctl --user is-enabled sleeve-gateway.service >/dev/null 2>&1; then
  printf 'STILL ENABLED: sleeve-gateway.service\n'
  remaining=1
fi

if [[ "$remaining" -eq 0 ]]; then
  printf 'No known Sleev files or service remain in the checked locations.\n'
else
  printf 'Some Sleev items remain; inspect the paths listed above.\n' >&2
  exit 1
fi
