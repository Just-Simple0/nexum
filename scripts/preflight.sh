#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage: preflight.sh [options] <contract-file>

Validate a Nexum Codex route without creating a model run.

Options:
  --role <builder|verifier>                         Default: builder
  --model <gpt-5.6-terra|gpt-5.6-luna>             Default: gpt-5.6-terra
  --effort <low|medium|high|xhigh|max>             Default: high
  --project <directory>                             Default: current directory
  --quiet                                           Print no success report
  --help                                            Show this help
EOF
}

role="builder"
model="gpt-5.6-terra"
effort="high"
project_dir="$PWD"
quiet=false
contract_file=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --role) [[ $# -ge 2 ]] || { echo "Missing value for --role" >&2; exit 64; }; role="$2"; shift 2 ;;
    --model) [[ $# -ge 2 ]] || { echo "Missing value for --model" >&2; exit 64; }; model="$2"; shift 2 ;;
    --effort) [[ $# -ge 2 ]] || { echo "Missing value for --effort" >&2; exit 64; }; effort="$2"; shift 2 ;;
    --project) [[ $# -ge 2 ]] || { echo "Missing value for --project" >&2; exit 64; }; project_dir="$2"; shift 2 ;;
    --quiet) quiet=true; shift ;;
    --help|-h) usage; exit 0 ;;
    --) shift; [[ $# -eq 1 ]] || { usage >&2; exit 64; }; contract_file="$1"; shift ;;
    -*) echo "Unknown option: $1" >&2; usage >&2; exit 64 ;;
    *) [[ -z "$contract_file" ]] || { usage >&2; exit 64; }; contract_file="$1"; shift ;;
  esac
done

[[ -n "$contract_file" ]] || { usage >&2; exit 64; }
case "$role" in builder|verifier) ;; *) echo "Role must be builder or verifier." >&2; exit 64 ;; esac
case "$model" in gpt-5.6-terra|gpt-5.6-luna) ;; *) echo "Unsupported Nexum worker model: $model" >&2; exit 64 ;; esac
case "$effort" in low|medium|high|xhigh|max) ;; *) echo "Unsupported reasoning effort: $effort" >&2; exit 64 ;; esac
[[ -s "$contract_file" ]] || { echo "Contract file is missing or empty: $contract_file" >&2; exit 1; }
[[ -d "$project_dir" ]] || { echo "Project directory not found: $project_dir" >&2; exit 1; }
git -C "$project_dir" rev-parse --is-inside-work-tree >/dev/null 2>&1 || { echo "Project directory is not a Git worktree: $project_dir" >&2; exit 1; }
command -v codex >/dev/null 2>&1 || { echo "Codex CLI was not found in PATH." >&2; exit 127; }

help_text="$(codex exec --help 2>&1)"
for option in --sandbox --add-dir --model --config --cd; do
  grep -Fq -- "$option" <<< "$help_text" || { echo "Installed Codex CLI does not support $option." >&2; exit 1; }
done

temp_dir="$project_dir/.nexum/tmp"
mkdir -p "$temp_dir"
probe_file="$(mktemp "$temp_dir/preflight.XXXXXX")"
rm -f "$probe_file"

if [[ "$quiet" == false ]]; then
  printf '%s\n' \
    'preflight: PASS' \
    "role: $role" \
    "model: $model" \
    "reasoning_effort: $effort" \
    "project: $project_dir" \
    "temp_dir: $temp_dir" \
    "contract: $contract_file"
fi
