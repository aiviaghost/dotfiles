#!/usr/bin/env bash
#
# install.sh — symlink every file under config/ into ~/.config.
#
# Usage: ./install.sh [--copy] [--dry-run]
#
#   --copy     copy files instead of symlinking them
#   --dry-run  only print what would happen
#
# Any existing file at a target path is moved into
# ~/.config-backup-<timestamp>/ (same relative path) before being replaced.
# Files are linked one by one, so unrelated files in e.g. ~/.config/fish stay put.

set -euo pipefail

MODE=link
DRY=0
for arg in "$@"; do
  case "$arg" in
    --copy) MODE=copy ;;
    --dry-run) DRY=1 ;;
    *) echo "error: unknown argument '$arg'" >&2; exit 1 ;;
  esac
done

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SRC="$REPO/config"
DEST="${XDG_CONFIG_HOME:-$HOME/.config}"
BACKUP="$HOME/.config-backup-$(date +%Y%m%d-%H%M%S)"

run() {
  if [[ "$DRY" == 1 ]]; then echo "  would run: $*"; else "$@"; fi
}

while IFS= read -r -d '' file; do
  rel="${file#"$SRC"/}"
  target="$DEST/$rel"

  # Already linked to this repo: nothing to do.
  if [[ -L "$target" && "$(readlink -f "$target")" == "$file" ]]; then
    echo "ok       $rel"
    continue
  fi

  if [[ -e "$target" || -L "$target" ]]; then
    echo "backup   $rel -> $BACKUP/$rel"
    run mkdir -p "$(dirname "$BACKUP/$rel")"
    run mv "$target" "$BACKUP/$rel"
  fi

  run mkdir -p "$(dirname "$target")"
  if [[ "$MODE" == copy ]]; then
    echo "copy     $rel"
    run cp -a "$file" "$target"
  else
    echo "link     $rel"
    run ln -s "$file" "$target"
  fi
done < <(find "$SRC" -type f -print0 | sort -z)

[[ -d "$BACKUP" ]] && echo "Backed up replaced files to $BACKUP"
echo "Done."
