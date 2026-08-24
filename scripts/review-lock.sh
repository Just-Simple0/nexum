#!/usr/bin/env bash
set -euo pipefail

lock_dir="${NEXUM_ROOT:-.nexum}/locks/insane-review.lock"
command="${1:-}"

acquire() {
  mkdir -p "$(dirname "$lock_dir")"
  if ! mkdir "$lock_dir" 2>/dev/null; then
    echo "insane-review lock is already held: $lock_dir" >&2
    exit 75
  fi
  printf '%s\n' "pid=$$" "started_at=$(date -u +%Y-%m-%dT%H:%M:%SZ)" > "$lock_dir/owner"
}

case "$command" in
  status)
    [[ -d "$lock_dir" ]] && { echo "locked"; exit 0; } || { echo "unlocked"; exit 1; }
    ;;
  release)
    [[ -d "$lock_dir" ]] || { echo "No review lock exists." >&2; exit 1; }
    rm -f "$lock_dir/owner"
    rmdir "$lock_dir"
    ;;
  with)
    shift
    [[ "${1:-}" == "--" ]] || { echo "Usage: $0 with -- <review-command>" >&2; exit 64; }
    shift
    [[ $# -gt 0 ]] || { echo "A review command is required." >&2; exit 64; }
    acquire
    trap 'rm -f "$lock_dir/owner"; rmdir "$lock_dir"' EXIT INT TERM
    "$@"
    ;;
  *)
    echo "Usage: $0 {status|release|with -- <review-command>}" >&2
    exit 64
    ;;
esac
