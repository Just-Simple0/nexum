#!/usr/bin/env bash
set -euo pipefail

base_ref="HEAD"
while [[ $# -gt 0 ]]; do
  case "$1" in
    --base) base_ref="$2"; shift 2 ;;
    *) echo "Usage: $0 [--base <git-ref>]" >&2; exit 64 ;;
  esac
done

git rev-parse --verify "$base_ref" >/dev/null
changed="$(git diff --name-only "$base_ref" --)"
if [[ -z "$changed" ]]; then
  echo "PASS: no changes from $base_ref"
  exit 0
fi

invalid=""
while IFS= read -r path; do
  case "$path" in
    test/*|tests/*|__tests__/*|spec/*|specs/*|fixtures/*|tmp/*|.nexum/*) ;;
    *) invalid+="$path"$'\n' ;;
  esac
done <<< "$changed"

if [[ -n "$invalid" ]]; then
  printf 'FAIL: verifier changed prohibited paths:\n' >&2
  while IFS= read -r path; do
    [[ -n "$path" ]] && printf '  %s\n' "$path" >&2
  done <<< "$invalid"
  exit 1
fi

printf 'PASS: verifier changes are confined to allowed paths:\n'
while IFS= read -r path; do
  printf '  %s\n' "$path"
done <<< "$changed"
