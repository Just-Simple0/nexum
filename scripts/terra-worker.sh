#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage: terra-worker.sh [options] <contract-file>

Options:
  --role <builder|verifier>  Worker role (default: builder)
  --model <model>            gpt-5.6-terra or gpt-5.6-luna (default: gpt-5.6-terra)
  --effort <level>           low, medium, high, xhigh, or max (default: high)
  --project <directory>     Project working directory (default: current directory)
  --output <file>           Write Codex's final response to this file
  --session-record <file>   Record the Codex session ID and run boundary metadata
  --dry-run                 Validate inputs and print the planned invocation
  --help                    Show this help
EOF
}

role="builder"
model="gpt-5.6-terra"
effort="high"
project_dir="$PWD"
output_file=""
session_record=""
dry_run=false
contract_file=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --role)
      [[ $# -ge 2 ]] || { echo "Missing value for --role" >&2; exit 64; }
      role="$2"; shift 2 ;;
    --model)
      [[ $# -ge 2 ]] || { echo "Missing value for --model" >&2; exit 64; }
      model="$2"; shift 2 ;;
    --effort)
      [[ $# -ge 2 ]] || { echo "Missing value for --effort" >&2; exit 64; }
      effort="$2"; shift 2 ;;
    --project)
      [[ $# -ge 2 ]] || { echo "Missing value for --project" >&2; exit 64; }
      project_dir="$2"; shift 2 ;;
    --output)
      [[ $# -ge 2 ]] || { echo "Missing value for --output" >&2; exit 64; }
      output_file="$2"; shift 2 ;;
    --session-record)
      [[ $# -ge 2 ]] || { echo "Missing value for --session-record" >&2; exit 64; }
      session_record="$2"; shift 2 ;;
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
script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
[[ -d "$project_dir" ]] || { echo "Project directory not found: $project_dir" >&2; exit 1; }
project_dir="$(cd "$project_dir" && pwd -P)"
if [[ -n "$session_record" && -z "$output_file" ]]; then
  echo "--session-record requires --output so the final response remains durable." >&2
  exit 64
fi
"$script_dir/preflight.sh" --quiet --role "$role" --model "$model" --effort "$effort" --project "$project_dir" "$contract_file"
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
    "model: $model" \
    "reasoning_effort: $effort" \
    'sandbox: workspace-write' \
    "project: $project_dir" \
    "temp_dir: $temp_dir" \
    "contract: $contract_file" \
    "output: ${output_file:-<stdout>}" \
    "session_record: ${session_record:-<disabled>}"
  exit 0
fi

prompt="$(role_instruction)

--- Nexum contract ---
$(<"$contract_file")"

args=(exec --sandbox workspace-write --add-dir "$temp_dir" -C "$project_dir" -m "$model" -c "model_reasoning_effort=\"$effort\"")
[[ -n "$output_file" ]] && args+=(-o "$output_file")

if [[ -z "$session_record" ]]; then
  args+=("$prompt")
  TMPDIR="$temp_dir" exec codex "${args[@]}"
fi

record_dir="$(dirname "$session_record")"
[[ -d "$record_dir" ]] || { echo "Session record directory not found: $record_dir" >&2; exit 1; }
event_file="$(mktemp "$temp_dir/terra-events.XXXXXX")"
trap 'rm -f "$event_file"' EXIT
args+=(--json "$prompt")

set +e
TMPDIR="$temp_dir" codex "${args[@]}" | tee "$event_file"
codex_status=${PIPESTATUS[0]}
set -e

session_id="$(sed -nE 's/.*"thread_id"[[:space:]]*:[[:space:]]*"([^"]+)".*/\1/p' "$event_file" | head -n 1)"
if [[ -z "$session_id" ]]; then
  echo "Codex did not emit a session ID; no session record was written." >&2
  exit 1
fi

umask 077
record_tmp="$(mktemp "$record_dir/.nexum-session.XXXXXX")"
printf '%s\n' \
  "session_id: $session_id" \
  "project: $project_dir" \
  "temp_dir: $temp_dir" \
  "model: $model" \
  "reasoning_effort: $effort" \
  'resume_policy: fresh-sandbox-required' \
  "exit_code: $codex_status" > "$record_tmp"
mv "$record_tmp" "$session_record"

exit "$codex_status"
