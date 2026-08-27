#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
review_gate="$repo_root/scripts/review-gate.sh"
completion_check="$repo_root/scripts/completion-check.sh"
tmp_root="$(mktemp -d)"
cleanup() { rm -rf "$tmp_root"; }
trap cleanup EXIT

run_dir="$tmp_root/run"
mkdir -p "$run_dir/reviews/sol" "$run_dir/reviews/gemini" "$run_dir/findings"
mkdir -p "$run_dir/reviews/sol/package" "$run_dir/reviews/gemini/package" "$run_dir/verification"
printf '%s\n' 'risk: HIGH' 'sol_required: true' 'gemini_required: true' 'fix_review_cycles: 0' 'max_fix_review_cycles: 2' > "$run_dir/reviews/review-state.yaml"
printf '%s\n' 'reviewer: sol' 'status: COMPLETE' "package_path: $run_dir/reviews/sol/package" 'invocation: insane-review-skill' > "$run_dir/reviews/sol/report.md"
printf '%s\n' 'reviewer: gemini' 'status: COMPLETE' "package_path: $run_dir/reviews/gemini/package" 'invocation: omc-ask-antigravity-one-shot' > "$run_dir/reviews/gemini/report.md"
printf '%s\n' 'reviewer: sol' > "$run_dir/reviews/sol/package/manifest.yaml"
printf '%s\n' 'reviewer: gemini' > "$run_dir/reviews/gemini/package/manifest.yaml"

fail_count=0
pass() { echo "PASS: $1"; }
fail() { echo "FAIL: $1"; fail_count=$((fail_count + 1)); }

if "$review_gate" "$run_dir" > "$tmp_root/pass.out"; then pass 'passes when required independent reviews are complete'; else fail 'passes when required independent reviews are complete'; fi

sed -i.bak 's/^invocation: omc-ask-antigravity-one-shot$/invocation: omc-ask-gemini-one-shot/' "$run_dir/reviews/gemini/report.md"
rm -f "$run_dir/reviews/gemini/report.md.bak"
if "$review_gate" "$run_dir" > "$tmp_root/provenance.out" 2>&1; then fail 'rejects a stale Google invocation path'; else pass 'rejects a stale Google invocation path'; fi
printf '%s\n' 'reviewer: gemini' 'status: COMPLETE' "package_path: $run_dir/reviews/gemini/package" 'invocation: omc-ask-antigravity-one-shot' > "$run_dir/reviews/gemini/report.md"

finding="$run_dir/findings/R-SOL-001.md"
printf '%s\n' '# Finding' '- ID: R-SOL-001' '- Source: sol' '- Severity: HIGH' '- Status: VALID' '- Location: src/owned.txt:1' '' '## Problem' 'Problem.' '' '## Impact' 'Impact.' '' '## Evidence' 'Evidence.' '' '## Recommendation' 'Fix it.' '' '## Adjudication' 'Validated.' > "$finding"
if "$review_gate" "$run_dir" > "$tmp_root/open.out" 2>&1; then fail 'rejects an unresolved HIGH finding'; else pass 'rejects an unresolved HIGH finding'; fi

sed -i.bak 's/^- Status: VALID$/- Status: FIXED/' "$finding"
rm -f "$finding.bak"
if "$review_gate" "$run_dir" > "$tmp_root/fixed.out"; then pass 'passes after the HIGH finding is fixed'; else fail 'passes after the HIGH finding is fixed'; fi

printf '%s\n' '# Verification Report' 'status: PASS' > "$run_dir/verification/report.md"
printf '%s\n' '# Completion Report' > "$run_dir/completion-report.md"
printf '%s\n' 'run_id: review-gate-smoke' 'status: REVIEW' > "$run_dir/run-state.yaml"
if "$completion_check" "$run_dir" > "$tmp_root/completion.out"; then pass 'completion check invokes the V3 review gate'; else fail 'completion check invokes the V3 review gate'; fi

printf '%s\n' 'risk: HIGH' 'sol_required: true' 'gemini_required: true' 'fix_review_cycles: 3' 'max_fix_review_cycles: 2' > "$run_dir/reviews/review-state.yaml"
if "$review_gate" "$run_dir" > "$tmp_root/budget.out" 2>&1; then fail 'rejects an exhausted fix-review budget'; else pass 'rejects an exhausted fix-review budget'; fi

echo '---'
if [[ "$fail_count" -eq 0 ]]; then echo 'review-gate.smoke.sh: ALL PASS'; else echo "review-gate.smoke.sh: $fail_count FAILURE(S)"; exit 1; fi
