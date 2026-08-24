#!/usr/bin/env bash
# Smoke test for the Terra adapter. It replaces Codex with a local argument
# capture shim, so it never creates a remote Codex run.
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
worker="$repo_root/scripts/terra-worker.sh"
tmp_root="$(mktemp -d)"
cleanup() { rm -rf "$tmp_root"; }
trap cleanup EXIT

project_dir="$tmp_root/project"
contract_file="$tmp_root/contract.md"
fake_bin="$tmp_root/bin"
capture_file="$tmp_root/codex-args.txt"
mkdir -p "$project_dir" "$fake_bin"
git -C "$project_dir" init -q
printf '%s\n' '# Contract' '## Objective' 'Add the requested bounded behavior.' > "$contract_file"

cat > "$fake_bin/codex" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
if [[ "${1:-}" == "exec" && "${2:-}" == "--help" ]]; then
  printf '%s\n' -- '--sandbox' '--add-dir' '--model' '--config' '--cd'
  exit 0
fi
printf '%s\n' "$@" > "$TERRA_CAPTURE"
EOF
chmod +x "$fake_bin/codex"

fail_count=0
pass() { echo "PASS: $1"; }
fail() { echo "FAIL: $1"; fail_count=$((fail_count + 1)); }
expect_contains() {
  local needle="$1"
  local file="$2"
  if grep -Fq -- "$needle" "$file"; then pass "$3"; else fail "$3"; fi
}

help_out="$tmp_root/help.out"
if "$worker" --help > "$help_out"; then
  expect_contains '--role' "$help_out" 'help lists role control'
  expect_contains '--dry-run' "$help_out" 'help lists dry-run control'
else
  fail 'help exits successfully'
fi

no_contract_status=0
if "$worker" > "$tmp_root/no-contract.out" 2>&1; then
  fail 'missing contract is rejected with usage status'
else
  no_contract_status=$?
  if [[ "$no_contract_status" -eq 64 ]]; then
    pass 'missing contract exits with usage status'
  else
    fail "missing contract exits with status $no_contract_status instead of 64"
  fi
fi

dry_run_out="$tmp_root/dry-run.out"
if PATH="$fake_bin:$PATH" "$worker" --dry-run --role builder --model gpt-5.6-luna --effort medium --project "$project_dir" --output "$tmp_root/handoff.md" "$contract_file" > "$dry_run_out"; then
  expect_contains 'mode: dry-run' "$dry_run_out" 'dry-run succeeds'
  expect_contains 'model: gpt-5.6-luna' "$dry_run_out" 'dry-run accepts selected Luna model'
  expect_contains 'reasoning_effort: medium' "$dry_run_out" 'dry-run accepts selected effort'
  expect_contains 'sandbox: workspace-write' "$dry_run_out" 'dry-run requires a writable workspace'
else
  fail 'dry-run exits successfully'
fi

if PATH="$fake_bin:$PATH" TERRA_CAPTURE="$capture_file" "$worker" --role builder --project "$project_dir" --output "$tmp_root/handoff.md" "$contract_file"; then
  expect_contains 'exec' "$capture_file" 'invokes codex exec'
  expect_contains '-C' "$capture_file" 'passes project directory flag'
  expect_contains "$project_dir" "$capture_file" 'passes project directory'
  expect_contains '--sandbox' "$capture_file" 'passes sandbox flag'
  expect_contains 'workspace-write' "$capture_file" 'uses writable workspace sandbox'
  expect_contains '--add-dir' "$capture_file" 'allows the project temporary directory'
  expect_contains "$project_dir/.nexum/tmp" "$capture_file" 'passes project temporary directory'
  expect_contains 'gpt-5.6-terra' "$capture_file" 'pins Terra model'
  expect_contains 'model_reasoning_effort="high"' "$capture_file" 'pins reasoning effort'
  expect_contains 'You are the Terra implementation worker in Nexum.' "$capture_file" 'includes builder role boundary'
  expect_contains 'Add the requested bounded behavior.' "$capture_file" 'includes contract body'
else
  fail 'builder invocation exits successfully through shim'
fi

if PATH="$fake_bin:$PATH" TERRA_CAPTURE="$capture_file" "$worker" --role verifier --project "$project_dir" "$contract_file"; then
  expect_contains 'You are the Terra verification worker in Nexum.' "$capture_file" 'includes verifier role boundary'
  expect_contains 'Do not modify production code' "$capture_file" 'includes verifier write restriction'
else
  fail 'verifier invocation exits successfully through shim'
fi

if "$worker" --dry-run --role invalid --project "$project_dir" "$contract_file" > "$tmp_root/invalid-role.out" 2>&1; then
  fail 'invalid role is rejected'
else
  pass 'invalid role is rejected'
fi

if PATH="$fake_bin:$PATH" "$worker" --dry-run --model invalid --project "$project_dir" "$contract_file" > "$tmp_root/invalid-model.out" 2>&1; then
  fail 'invalid model is rejected'
else
  pass 'invalid model is rejected'
fi

if "$worker" --dry-run --project "$tmp_root/missing" "$contract_file" > "$tmp_root/missing-project.out" 2>&1; then
  fail 'missing project is rejected'
else
  pass 'missing project is rejected'
fi

echo '---'
if [[ "$fail_count" -eq 0 ]]; then
  echo 'terra-worker.smoke.sh: ALL PASS'
  exit 0
fi
echo "terra-worker.smoke.sh: $fail_count FAILURE(S)"
exit 1
