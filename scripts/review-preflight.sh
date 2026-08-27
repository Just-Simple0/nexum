#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage: review-preflight.sh [--google-command <command>]

Verifies that the Antigravity CLI required by Nexum's independent Google
review lane is available. This check does not send a model prompt.
EOF
}

google_command="agy"
while [[ $# -gt 0 ]]; do
  case "$1" in
    --google-command)
      [[ $# -ge 2 ]] || { usage >&2; exit 64; }
      google_command="$2"
      shift 2
      ;;
    --help|-h)
      usage
      exit 0
      ;;
    *)
      echo "Unknown option: $1" >&2
      usage >&2
      exit 64
      ;;
  esac
done

command -v "$google_command" >/dev/null 2>&1 || {
  echo "FAIL: Antigravity command not found: $google_command" >&2
  echo "Install Antigravity CLI and ensure its agy binary is on PATH." >&2
  exit 1
}

version="$($google_command --version 2>&1)" || {
  echo "FAIL: Antigravity command failed: $google_command --version" >&2
  exit 1
}

[[ -n "$version" ]] || { echo 'FAIL: Antigravity did not report a version.' >&2; exit 1; }
printf 'PASS: Antigravity ready (%s)\n' "$version"
