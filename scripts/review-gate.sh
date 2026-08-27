#!/usr/bin/env bash
set -euo pipefail

if [[ $# -ne 1 ]]; then
  echo "Usage: $0 <run-directory>" >&2
  exit 64
fi

run_dir="${1%/}"
state_file="$run_dir/reviews/review-state.yaml"
[[ -f "$state_file" ]] || { echo "FAIL: missing review state: $state_file" >&2; exit 1; }

value() {
  local key="$1"
  sed -nE "s/^${key}: (.+)$/\\1/p" "$state_file" | head -n 1
}

sol_required="$(value sol_required)"
gemini_required="$(value gemini_required)"
cycles="$(value fix_review_cycles)"
max_cycles="$(value max_fix_review_cycles)"
risk="$(value risk)"
for required in risk sol_required gemini_required fix_review_cycles max_fix_review_cycles; do
  [[ -n "$(value "$required")" ]] || { echo "FAIL: review state is missing $required" >&2; exit 1; }
done
[[ "$sol_required" =~ ^(true|false)$ ]] || { echo 'FAIL: sol_required must be true or false' >&2; exit 1; }
[[ "$gemini_required" =~ ^(true|false)$ ]] || { echo 'FAIL: gemini_required must be true or false' >&2; exit 1; }
[[ "$cycles" =~ ^[0-9]+$ && "$max_cycles" =~ ^[0-9]+$ ]] || { echo 'FAIL: review cycle counts must be integers' >&2; exit 1; }
(( cycles <= max_cycles )) || { echo "FAIL: review cycles exceed budget ($cycles/$max_cycles)" >&2; exit 1; }
case "$risk" in
  LOW) [[ "$sol_required" == false && "$gemini_required" == false ]] || { echo 'FAIL: LOW must not require an external review' >&2; exit 1; } ;;
  MEDIUM) [[ "$sol_required" == true ]] || { echo 'FAIL: MEDIUM requires a Sol review' >&2; exit 1; } ;;
  HIGH|CRITICAL) [[ "$sol_required" == true && "$gemini_required" == true ]] || { echo "FAIL: $risk requires Sol and Gemini reviews" >&2; exit 1; } ;;
  *) echo "FAIL: unsupported or unset review risk: $risk" >&2; exit 1 ;;
esac

check_reviewer() {
  local reviewer="$1"
  local required="$2"
  [[ "$required" == true ]] || return 0
  local report="$run_dir/reviews/$reviewer/report.md"
  local package_dir="$run_dir/reviews/$reviewer/package"
  [[ -f "$report" ]] || { echo "FAIL: missing required $reviewer review report" >&2; exit 1; }
  [[ -f "$package_dir/manifest.yaml" ]] || { echo "FAIL: missing required $reviewer review package" >&2; exit 1; }
  rg -q "^reviewer: $reviewer$" "$report" || { echo "FAIL: $reviewer report identity does not match" >&2; exit 1; }
  rg -q '^status: COMPLETE$' "$report" || { echo "FAIL: required $reviewer review is not COMPLETE" >&2; exit 1; }
  rg -q "^package_path: $package_dir$" "$report" || { echo "FAIL: $reviewer report does not identify its package" >&2; exit 1; }
  local expected_invocation
  case "$reviewer" in
    sol) expected_invocation='insane-review-skill' ;;
    gemini) expected_invocation='omc-ask-antigravity-one-shot' ;;
  esac
  rg -q "^invocation: $expected_invocation$" "$report" || { echo "FAIL: $reviewer report invocation does not match $expected_invocation" >&2; exit 1; }
}

check_reviewer sol "$sol_required"
check_reviewer gemini "$gemini_required"

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
"$script_dir/finding-check.sh" --require-resolved-blocking "$run_dir/findings"
echo "PASS: review gate succeeded"
