#!/usr/bin/env bash
set -euo pipefail

if [[ $# -ne 1 ]]; then
  echo "Usage: $0 <run-id>" >&2
  exit 64
fi

run_id="$1"
if [[ ! "$run_id" =~ ^[A-Za-z0-9][A-Za-z0-9._-]*$ ]]; then
  echo "Run ID may contain letters, digits, dot, underscore, and hyphen only." >&2
  exit 64
fi

root="${NEXUM_ROOT:-.nexum}"
run_dir="$root/runs/$run_id"
if [[ -e "$run_dir" ]]; then
  echo "Run already exists: $run_dir" >&2
  exit 1
fi

mkdir -p "$run_dir"/{contracts,research,verification,reviews,findings}
printf '%s\n' "run_id: $run_id" "status: PLANNED" > "$run_dir/run-state.yaml"
printf '%s\n' \
  'risk: UNSET' \
  'sol_required: false' \
  'gemini_required: false' \
  'fix_review_cycles: 0' \
  'max_fix_review_cycles: 2' > "$run_dir/reviews/review-state.yaml"
echo "Initialized $run_dir"
