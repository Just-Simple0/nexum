#!/usr/bin/env bash
# Smoke test for the zero-model-call route preflight.
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
preflight="$repo_root/scripts/preflight.sh"
tmp_root="$(mktemp -d)"
cleanup() { rm -rf "$tmp_root"; }
trap cleanup EXIT

project_dir="$tmp_root/project"
contract_file="$tmp_root/contract.md"
fake_bin="$tmp_root/bin"
mkdir -p "$project_dir" "$fake_bin"
git -C "$project_dir" init -q
printf '%s\n' '# Contract' 'Objective: bounded test.' > "$contract_file"

cat > "$fake_bin/codex" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
if [[ "${1:-}" == "exec" && "${2:-}" == "--help" ]]; then
  printf '%s\n' -- '--sandbox' '--add-dir' '--model' '--config' '--cd' '--json'
  exit 0
fi
exit 97
EOF
chmod +x "$fake_bin/codex"

fail_count=0
pass() { echo "PASS: $1"; }
fail() { echo "FAIL: $1"; fail_count=$((fail_count + 1)); }

success_out="$tmp_root/success.out"
if PATH="$fake_bin:$PATH" "$preflight" --role builder --model gpt-5.6-terra --effort high --project "$project_dir" "$contract_file" > "$success_out"; then
  grep -Fq 'preflight: PASS' "$success_out" && pass 'valid route passes without a model run' || fail 'valid route reports PASS'
  [[ -d "$project_dir/.nexum/tmp" ]] && pass 'creates project-local temporary directory' || fail 'creates project-local temporary directory'
else
  fail 'valid route exits successfully'
fi

if PATH="$fake_bin:$PATH" "$preflight" --model invalid --project "$project_dir" "$contract_file" > "$tmp_root/invalid-model.out" 2>&1; then
  fail 'invalid model is rejected'
else
  pass 'invalid model is rejected'
fi

: > "$tmp_root/empty-contract.md"
if PATH="$fake_bin:$PATH" "$preflight" --project "$project_dir" "$tmp_root/empty-contract.md" > "$tmp_root/empty-contract.out" 2>&1; then
  fail 'empty contract is rejected'
else
  pass 'empty contract is rejected'
fi

echo '---'
if [[ "$fail_count" -eq 0 ]]; then
  echo 'preflight.smoke.sh: ALL PASS'
  exit 0
fi
echo "preflight.smoke.sh: $fail_count FAILURE(S)"
exit 1
