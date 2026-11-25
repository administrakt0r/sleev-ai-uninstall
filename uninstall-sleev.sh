#!/usr/bin/env bash
set -euo pipefail

DRY_RUN=0
ASSUME_YES=0

usage() {
  printf 'Usage: %s [--dry-run] [--yes]\n' "$0"
  printf '  --dry-run  Show cleanup targets without changing anything.\n'
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

if [[ "$DRY_RUN" -eq 0 && "$ASSUME_YES" -eq 0 && ! -t 0 ]]; then
  printf 'Refusing non-interactive cleanup without --yes. Use --dry-run first.\n' >&2
  exit 2
fi

HOME_DIR="$(realpath -e -- "${HOME:?HOME must be set}")"
if [[ "$HOME_DIR" == / || ! -d "$HOME_DIR" ]]; then
  printf 'Refusing invalid home directory.\n' >&2
  exit 2
fi
unit=sleeve-gateway.service
unit_path="$HOME_DIR/.config/systemd/user/$unit"
unit_link="$HOME_DIR/.config/systemd/user/default.target.wants/$unit"
targets=(
  "$unit_link" "$unit_path"
  "$HOME_DIR/.local/bin/sleev"
  "$HOME_DIR/.config/sleev"
  "$HOME_DIR/.local/share/sleev"
  "$HOME_DIR/.local/state/sleev"
  "$HOME_DIR/.cache/sleev-gateway"
)

# A lexical home prefix alone is not enough: a symlink in an ancestor
# redirects the deletion. A symlink at the target itself may be unlinked.
safe_parent() {
  local target="$1" parent
  [[ "$target" == "$HOME_DIR/"* ]] || return 1
  parent="${target%/*}"
  while [[ "$parent" != "$HOME_DIR" ]]; do
    [[ "$parent" == "$HOME_DIR/"* && ! -L "$parent" ]] || return 1
    parent="${parent%/*}"
  done
}

present() { [[ -e "$1" || -L "$1" ]]; }

printf 'Sleev cleanup targets on %s\n' "$HOME_DIR"
for target in "${targets[@]}"; do
  if ! safe_parent "$target"; then
    printf '[SKIP: unsafe ancestor] %s\n' "$target"
  elif present "$target"; then
    printf '[FOUND] %s\n' "$target"
  else
    printf '[NOT FOUND] %s\n' "$target"
  fi
done
printf 'User systemd unit: %s (checked before cleanup)\n' "$unit"
printf 'Global npm package: sleev (checked before removal)\n'
printf 'Browser data and AI tool configuration are left for manual review.\n'

if [[ "$DRY_RUN" -eq 1 ]]; then
  printf '\nDry run only; no changes made.\n'
  exit 0
fi

if [[ "$ASSUME_YES" -eq 0 ]]; then
  printf '\nThis permanently deletes Sleev binaries, settings, credentials, session database, logs and cache. No backup will be made.\n'
  read -r -p 'Type REMOVE SLEEV to continue: ' answer
  [[ "$answer" == 'REMOVE SLEEV' ]] || { printf 'Cancelled.\n'; exit 1; }
fi

remaining=0
systemd_checked=0
if ! safe_parent "$unit_path" || ! safe_parent "$unit_link" || [[ -L "$unit_path" ]]; then
  printf 'Refusing to modify a unit with an unsafe path; inspect it manually.\n' >&2
  exit 1
fi
if command -v systemctl >/dev/null 2>&1; then
  if state="$(systemctl --user show -p LoadState --value "$unit" 2>/dev/null)"; then
    systemd_checked=1
    if [[ "$state" != not-found ]]; then
      fragment="$(systemctl --user show -p FragmentPath --value "$unit")"
      if [[ "$fragment" != "$unit_path" ]]; then
        printf 'Unexpected systemd unit location; refusing cleanup: %s\n' "$fragment" >&2
        exit 1
      fi
      if ! systemctl --user disable --now "$unit"; then
        printf 'Could not disable/stop the gateway; no application files removed.\n' >&2
        exit 1
      fi
      active="$(systemctl --user show -p ActiveState --value "$unit")"
      if [[ "$active" != inactive && "$active" != failed ]]; then
        printf 'Gateway is not stopped; no application files removed.\n' >&2
        exit 1
      fi
    fi
  else
    printf 'Cannot verify the user systemd manager.\n' >&2
    if present "$unit_path" || present "$unit_link"; then exit 1; fi
    remaining=1
  fi
elif present "$unit_path" || present "$unit_link"; then
  printf 'systemctl unavailable; inspect the gateway service before cleanup.\n' >&2
  exit 1
fi

# The npm package name is exact; never invoke its lifecycle scripts.
npm_has_sleev() {
  local packages line
  packages="$(npm list -g --depth=0 --parseable --offline 2>/dev/null)" || return 2
  while IFS= read -r line; do
    [[ "$line" == */node_modules/sleev ]] && return 0
  done <<< "$packages"
  return 1
}
if command -v npm >/dev/null 2>&1; then
  if npm_has_sleev; then
    if ! npm uninstall -g sleev --ignore-scripts --offline --no-audit --no-fund; then
      printf 'npm uninstall failed.\n' >&2; remaining=1
    fi
  elif [[ "$?" -ne 1 ]]; then
    printf 'Unable to inspect global npm packages.\n' >&2; remaining=1
  fi
fi

for target in "${targets[@]}"; do
  if ! safe_parent "$target"; then
    printf 'SKIPPED: unsafe ancestor: %s\n' "$target" >&2; remaining=1
  elif present "$target"; then
    if rm -rf --one-file-system -- "$target" && ! present "$target"; then
      printf 'Removed %s\n' "$target"
    else
      printf 'FAILED: %s\n' "$target" >&2; remaining=1
    fi
  fi
done

printf '\nVerification of primary locations:\n'
for target in "${targets[@]}"; do
  if ! safe_parent "$target" || present "$target"; then
    printf 'NOT CLEARED: %s\n' "$target" >&2; remaining=1
  fi
done
if [[ "$systemd_checked" -eq 1 ]]; then
  if ! systemctl --user daemon-reload ||
     ! state="$(systemctl --user show -p LoadState --value "$unit" 2>/dev/null)" ||
     [[ "$state" != not-found ]]; then
    printf 'User unit removal could not be verified.\n' >&2; remaining=1
  fi
fi
if command -v npm >/dev/null 2>&1; then
  if npm_has_sleev; then
    printf 'Global npm sleev package remains.\n' >&2; remaining=1
  elif [[ "$?" -ne 1 ]]; then
    printf 'Cannot verify global npm package removal.\n' >&2; remaining=1
  fi
fi
if command -v sleev >/dev/null 2>&1; then
  printf 'Sleev command remains in PATH.\n' >&2; remaining=1
fi
printf 'Review browser site data for sleev.ai and restore any Sleev proxy settings manually.\n'
if [[ "$remaining" -eq 0 ]]; then
  printf 'Known application targets cleared; see manual checks in README.\n'
else
  printf 'Cleanup incomplete; review the warnings above.\n' >&2
  exit 1
fi
