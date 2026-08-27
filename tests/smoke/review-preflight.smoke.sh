#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
preflight="$repo_root/scripts/review-preflight.sh"
tmp_root="$(mktemp -d)"
cleanup() { rm -rf "$tmp_root"; }
trap cleanup EXIT

fail_count=0
pass() { echo "PASS: $1"; }
fail() { echo "FAIL: $1"; fail_count=$((fail_count + 1)); }

mkdir -p "$tmp_root/bin"
printf '%s\n' '#!/usr/bin/env bash' '[[ "$1" == "--version" ]] || exit 64' 'echo 1.2.3' > "$tmp_root/bin/agy"
chmod +x "$tmp_root/bin/agy"

if PATH="$tmp_root/bin:$PATH" "$preflight" > "$tmp_root/available.out"; then
  pass 'accepts an available Antigravity command'
else
  fail 'rejects an available Antigravity command'
fi

if PATH="/usr/bin:/bin" "$preflight" > "$tmp_root/missing.out" 2>&1; then
  fail 'accepts a missing Antigravity command'
else
  pass 'rejects a missing Antigravity command'
fi

if "$preflight" --unknown > "$tmp_root/unknown.out" 2>&1; then
  fail 'accepts an unknown option'
else
  pass 'rejects an unknown option'
fi

echo '---'
if [[ "$fail_count" -eq 0 ]]; then
  echo 'review-preflight.smoke.sh: ALL PASS'
else
  echo "review-preflight.smoke.sh: $fail_count FAILURE(S)"
  exit 1
fi
