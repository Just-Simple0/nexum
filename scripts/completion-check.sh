#!/usr/bin/env bash
set -euo pipefail

if [[ $# -ne 1 ]]; then
  echo "Usage: $0 <run-directory>" >&2
  exit 64
fi

run_dir="${1%/}"
required=("run-state.yaml" "verification/report.md" "completion-report.md")
missing=()
for item in "${required[@]}"; do
  [[ -f "$run_dir/$item" ]] || missing+=("$item")
done
if [[ ${#missing[@]} -gt 0 ]]; then
  printf 'FAIL: missing completion artifacts:\n' >&2
  printf '  %s\n' "${missing[@]}" >&2
  exit 1
fi

if ! rg -q '^status: PASS$' "$run_dir/verification/report.md"; then
  echo "FAIL: verification report is not PASS" >&2
  exit 1
fi
if [[ -f "$run_dir/reviews/review-state.yaml" ]]; then
  script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  "$script_dir/review-gate.sh" "$run_dir"
fi
if rg -q '^(- Severity: (BLOCKER|HIGH)|severity: (BLOCKER|HIGH))' "$run_dir/findings" 2>/dev/null; then
  if ! rg -q '^(- Status: (FIXED|INVALID)|status: (FIXED|INVALID))' "$run_dir/findings" 2>/dev/null; then
    echo "FAIL: a BLOCKER/HIGH finding may remain unresolved" >&2
    exit 1
  fi
fi
echo "PASS: completion artifact preflight succeeded"
