#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage: terra-worker.sh [options] <contract-file>

Options:
  --role <builder|verifier>  Worker role (default: builder)
  --project <directory>     Project working directory (default: current directory)
  --output <file>           Write Codex's final response to this file
  --dry-run                 Validate inputs and print the planned invocation
  --help                    Show this help
EOF
}

role="builder"
project_dir="$PWD"
output_file=""
dry_run=false
contract_file=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --role)
      [[ $# -ge 2 ]] || { echo "Missing value for --role" >&2; exit 64; }
      role="$2"; shift 2 ;;
    --project)
      [[ $# -ge 2 ]] || { echo "Missing value for --project" >&2; exit 64; }
      project_dir="$2"; shift 2 ;;
    --output)
      [[ $# -ge 2 ]] || { echo "Missing value for --output" >&2; exit 64; }
      output_file="$2"; shift 2 ;;
    --dry-run) dry_run=true; shift ;;
    --help|-h) usage; exit 0 ;;
    --)
      shift
      [[ $# -eq 1 ]] || { usage >&2; exit 64; }
      contract_file="$1"; shift ;;
    -*) echo "Unknown option: $1" >&2; usage >&2; exit 64 ;;
    *)
      [[ -z "$contract_file" ]] || { usage >&2; exit 64; }
      contract_file="$1"; shift ;;
  esac
done

[[ -n "$contract_file" ]] || { usage >&2; exit 64; }
case "$role" in builder|verifier) ;; *) echo "Role must be builder or verifier." >&2; exit 64 ;; esac
[[ -f "$contract_file" ]] || { echo "Contract file not found: $contract_file" >&2; exit 1; }
[[ -d "$project_dir" ]] || { echo "Project directory not found: $project_dir" >&2; exit 1; }
temp_dir="$project_dir/.nexum/tmp"

role_instruction() {
  case "$role" in
    builder)
      printf '%s\n' \
        'You are the Terra implementation worker in Nexum.' \
        'Implement only the supplied contract. Inspect relevant files, make the requested change, run required checks, and report changed files and evidence.' \
        'The sandbox may write only inside the project. Use the inherited TMPDIR for temporary files.' \
        'Do not expand scope, alter contracts or risk, spawn agents, request approval, or declare final completion.'
      ;;
    verifier)
      printf '%s\n' \
        'You are the Terra verification worker in Nexum.' \
        'Judge the supplied change through execution evidence. Run the required checks and report PASS, FAIL, or INCONCLUSIVE with reproducible evidence.' \
        'Do not modify production code, production configuration, contracts, scope, or declare final completion. You may create only allowed verification artifacts.'
      ;;
  esac
}

if [[ "$dry_run" == true ]]; then
  printf '%s\n' \
    'mode: dry-run' \
    "role: $role" \
    'model: gpt-5.6-terra' \
    'reasoning_effort: high' \
    'sandbox: workspace-write' \
    "project: $project_dir" \
    "temp_dir: $temp_dir" \
    "contract: $contract_file" \
    "output: ${output_file:-<stdout>}"
  exit 0
fi

command -v codex >/dev/null 2>&1 || { echo "Codex CLI was not found in PATH." >&2; exit 127; }
mkdir -p "$temp_dir"
prompt="$(role_instruction)

--- Nexum contract ---
$(<"$contract_file")"

args=(exec --sandbox workspace-write --add-dir "$temp_dir" -C "$project_dir" -m gpt-5.6-terra -c 'model_reasoning_effort="high"')
[[ -n "$output_file" ]] && args+=(-o "$output_file")
args+=("$prompt")
TMPDIR="$temp_dir" exec codex "${args[@]}"
