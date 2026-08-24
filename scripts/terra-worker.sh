#!/usr/bin/env bash
set -euo pipefail

if [[ $# -lt 1 || $# -gt 2 ]]; then
  echo "Usage: $0 <task-contract-or-prompt-file> [project-directory]" >&2
  exit 64
fi

prompt_file="$1"
project_dir="${2:-$PWD}"
[[ -f "$prompt_file" ]] || { echo "Prompt file not found: $prompt_file" >&2; exit 1; }
[[ -d "$project_dir" ]] || { echo "Project directory not found: $project_dir" >&2; exit 1; }

exec codex exec -C "$project_dir" -m gpt-5.6-terra -c 'model_reasoning_effort="high"' "$(<"$prompt_file")"
