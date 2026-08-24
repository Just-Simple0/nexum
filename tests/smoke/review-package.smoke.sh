#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
package_script="$repo_root/scripts/review-package.sh"
tmp_root="$(mktemp -d)"
cleanup() { rm -rf "$tmp_root"; }
trap cleanup EXIT

project="$tmp_root/project"
run_dir="$tmp_root/run"
mkdir -p "$project/src"
git -C "$project" init -q
git -C "$project" config user.email nexum-test@example.invalid
git -C "$project" config user.name 'Nexum Smoke Test'
printf '%s\n' 'before' > "$project/src/owned.txt"
printf '%s\n' 'before' > "$project/unrelated.txt"
git -C "$project" add .
git -C "$project" commit -qm initial
printf '%s\n' 'after' > "$project/src/owned.txt"
printf '%s\n' 'changed' > "$project/unrelated.txt"
git -C "$project" add .
git -C "$project" commit -qm change

requirements="$tmp_root/requirement.md"
task_contract="$tmp_root/task.md"
shared_contract="$tmp_root/shared.md"
acceptance="$tmp_root/acceptance.md"
verification="$tmp_root/verification.md"
printf '%s\n' '# Requirement' 'Bounded change.' > "$requirements"
printf '%s\n' '# Task Contract' 'No Builder rationale is included.' > "$task_contract"
printf '%s\n' '# Shared Contract' 'Boundary.' > "$shared_contract"
printf '%s\n' '# Acceptance' '- [ ] owned path changes' > "$acceptance"
printf '%s\n' '# Verification Report' 'status: PASS' > "$verification"

fail_count=0
pass() { echo "PASS: $1"; }
fail() { echo "FAIL: $1"; fail_count=$((fail_count + 1)); }
expect_contains() { grep -Fq -- "$1" "$2" && pass "$3" || fail "$3"; }

if "$package_script" --run "$run_dir" --reviewer sol --project "$project" --requirements "$requirements" --task-contract "$task_contract" --shared-contract "$shared_contract" --acceptance "$acceptance" --verification "$verification" --base HEAD~1 --path src > "$tmp_root/package.out"; then
  package_dir="$run_dir/reviews/sol/package"
  [[ -f "$package_dir/manifest.yaml" && -f "$package_dir/diff.patch" ]] && pass 'creates the Sol package atomically' || fail 'creates the Sol package atomically'
  expect_contains 'src/owned.txt' "$package_dir/relevant-files.txt" 'includes the requested owned path'
  if grep -Fq 'unrelated.txt' "$package_dir/relevant-files.txt"; then fail 'excludes paths outside the requested review scope'; else pass 'excludes paths outside the requested review scope'; fi
  expect_contains 'builder-rationale-and-peer-review-excluded' "$package_dir/manifest.yaml" 'records the independence boundary'
else
  fail 'creates a restricted review package'
fi

if "$package_script" --run "$run_dir" --reviewer sol --project "$project" --requirements "$requirements" --task-contract "$task_contract" --acceptance "$acceptance" --verification "$verification" --base HEAD~1 > "$tmp_root/duplicate.out" 2>&1; then
  fail 'rejects overwriting an existing review package'
else
  pass 'rejects overwriting an existing review package'
fi

if "$package_script" --run "$run_dir" --reviewer gemini --project "$project" --requirements "$requirements" --task-contract "$task_contract" --acceptance "$acceptance" --verification "$verification" --base HEAD~1 > "$tmp_root/gemini.out"; then
  [[ -f "$run_dir/reviews/gemini/package/manifest.yaml" ]] && pass 'creates an independent Gemini package' || fail 'creates an independent Gemini package'
else
  fail 'creates an independent Gemini package'
fi

echo '---'
if [[ "$fail_count" -eq 0 ]]; then echo 'review-package.smoke.sh: ALL PASS'; else echo "review-package.smoke.sh: $fail_count FAILURE(S)"; exit 1; fi
