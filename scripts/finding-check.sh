#!/usr/bin/env bash
set -euo pipefail

usage() {
  echo "Usage: $0 [--require-resolved-blocking] <finding-file-or-directory>" >&2
}

require_resolved_blocking=false
if [[ "${1:-}" == "--require-resolved-blocking" ]]; then
  require_resolved_blocking=true
  shift
fi
[[ $# -eq 1 ]] || { usage; exit 64; }
target="$1"

files=()
if [[ -f "$target" ]]; then
  files=("$target")
elif [[ -d "$target" ]]; then
  while IFS= read -r -d '' file; do files+=("$file"); done < <(find "$target" -type f -name '*.md' -print0)
else
  echo "Finding target not found: $target" >&2
  exit 1
fi

if [[ ${#files[@]} -eq 0 ]]; then
  echo 'PASS: no finding artifacts to validate'
  exit 0
fi

failures=0
for file in "${files[@]}"; do
  for required in '^# Finding$' '^- ID: .+' '^- Source: (sol|gemini)$' '^- Severity: (BLOCKER|HIGH|MEDIUM|LOW)$' '^- Status: (OPEN|VALID|INVALID|UNCERTAIN|FIXED)$' '^- Location: .+' '^## Problem$' '^## Impact$' '^## Evidence$' '^## Recommendation$' '^## Adjudication$'; do
    if ! rg -q -- "$required" "$file"; then
      echo "FAIL: $file is missing required finding content: $required" >&2
      failures=$((failures + 1))
      break
    fi
  done

  if [[ "$require_resolved_blocking" == true ]]; then
    severity="$(sed -nE 's/^- Severity: (BLOCKER|HIGH|MEDIUM|LOW)$/\1/p' "$file" | head -n 1)"
    status="$(sed -nE 's/^- Status: (OPEN|VALID|INVALID|UNCERTAIN|FIXED)$/\1/p' "$file" | head -n 1)"
    if [[ "$severity" =~ ^(BLOCKER|HIGH)$ && ! "$status" =~ ^(FIXED|INVALID)$ ]]; then
      echo "FAIL: $file has unresolved $severity finding ($status)" >&2
      failures=$((failures + 1))
    fi
  fi
done

if [[ "$failures" -gt 0 ]]; then
  exit 1
fi
echo "PASS: validated ${#files[@]} finding artifact(s)"
