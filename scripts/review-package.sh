#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage: review-package.sh --run <run-directory> --reviewer <sol|gemini> \
  --project <repository> --requirements <file> --task-contract <file> \
  --acceptance <file> --verification <file> --base <git-ref> [options]

Options:
  --head <git-ref>       Change tip (default: HEAD)
  --shared-contract <file>
  --path <path>          Restrict the diff to a path; repeatable
  --help                 Show this help

Creates <run>/reviews/<reviewer>/package atomically. The package deliberately
contains only requirement, contract, acceptance, diff, relevant paths, and
verification evidence; it never copies Builder rationale or another review.
EOF
}

run_dir=""
reviewer=""
project_dir=""
requirements=""
task_contract=""
shared_contract=""
acceptance=""
verification=""
base_ref=""
head_ref="HEAD"
paths=()

while [[ $# -gt 0 ]]; do
  case "$1" in
    --run) [[ $# -ge 2 ]] || { usage >&2; exit 64; }; run_dir="$2"; shift 2 ;;
    --reviewer) [[ $# -ge 2 ]] || { usage >&2; exit 64; }; reviewer="$2"; shift 2 ;;
    --project) [[ $# -ge 2 ]] || { usage >&2; exit 64; }; project_dir="$2"; shift 2 ;;
    --requirements) [[ $# -ge 2 ]] || { usage >&2; exit 64; }; requirements="$2"; shift 2 ;;
    --task-contract) [[ $# -ge 2 ]] || { usage >&2; exit 64; }; task_contract="$2"; shift 2 ;;
    --shared-contract) [[ $# -ge 2 ]] || { usage >&2; exit 64; }; shared_contract="$2"; shift 2 ;;
    --acceptance) [[ $# -ge 2 ]] || { usage >&2; exit 64; }; acceptance="$2"; shift 2 ;;
    --verification) [[ $# -ge 2 ]] || { usage >&2; exit 64; }; verification="$2"; shift 2 ;;
    --base) [[ $# -ge 2 ]] || { usage >&2; exit 64; }; base_ref="$2"; shift 2 ;;
    --head) [[ $# -ge 2 ]] || { usage >&2; exit 64; }; head_ref="$2"; shift 2 ;;
    --path) [[ $# -ge 2 ]] || { usage >&2; exit 64; }; paths+=("$2"); shift 2 ;;
    --help|-h) usage; exit 0 ;;
    *) echo "Unknown option: $1" >&2; usage >&2; exit 64 ;;
  esac
done

case "$reviewer" in sol|gemini) ;; *) echo "Reviewer must be sol or gemini." >&2; exit 64 ;; esac
for value in "$run_dir" "$project_dir" "$requirements" "$task_contract" "$acceptance" "$verification" "$base_ref"; do
  [[ -n "$value" ]] || { usage >&2; exit 64; }
done
for file in "$requirements" "$task_contract" "$acceptance" "$verification"; do
  [[ -f "$file" ]] || { echo "Required input file not found: $file" >&2; exit 1; }
done
if [[ -n "$shared_contract" && ! -f "$shared_contract" ]]; then
  echo "Shared contract file not found: $shared_contract" >&2
  exit 1
fi
[[ -d "$project_dir" ]] || { echo "Project directory not found: $project_dir" >&2; exit 1; }
project_dir="$(cd "$project_dir" && pwd -P)"
git -C "$project_dir" rev-parse --is-inside-work-tree >/dev/null 2>&1 || {
  echo "Project directory is not a Git worktree: $project_dir" >&2
  exit 1
}
git -C "$project_dir" rev-parse --verify "$base_ref^{commit}" >/dev/null
git -C "$project_dir" rev-parse --verify "$head_ref^{commit}" >/dev/null

mkdir -p "$run_dir/reviews/$reviewer"
run_dir="$(cd "$run_dir" && pwd -P)"
package_dir="$run_dir/reviews/$reviewer/package"
[[ ! -e "$package_dir" ]] || { echo "Review package already exists: $package_dir" >&2; exit 1; }

temp_package="$(mktemp -d "$run_dir/reviews/$reviewer/.package.XXXXXX")"
cleanup() { rm -rf "$temp_package"; }
trap cleanup EXIT

cp "$requirements" "$temp_package/requirement.md"
cp "$task_contract" "$temp_package/task-contract.md"
cp "$acceptance" "$temp_package/acceptance-criteria.md"
cp "$verification" "$temp_package/verification-report.md"
if [[ -n "$shared_contract" ]]; then
  cp "$shared_contract" "$temp_package/shared-contract.md"
else
  printf '%s\n' '# Shared Contract' 'No shared contract was supplied for this task.' > "$temp_package/shared-contract.md"
fi

if [[ ${#paths[@]} -gt 0 ]]; then
  git -C "$project_dir" diff --binary "$base_ref...$head_ref" -- "${paths[@]}" > "$temp_package/diff.patch"
  git -C "$project_dir" diff --name-only "$base_ref...$head_ref" -- "${paths[@]}" > "$temp_package/relevant-files.txt"
else
  git -C "$project_dir" diff --binary "$base_ref...$head_ref" > "$temp_package/diff.patch"
  git -C "$project_dir" diff --name-only "$base_ref...$head_ref" > "$temp_package/relevant-files.txt"
fi

printf '%s\n' \
  "reviewer: $reviewer" \
  "project: $project_dir" \
  "base: $(git -C "$project_dir" rev-parse "$base_ref")" \
  "head: $(git -C "$project_dir" rev-parse "$head_ref")" \
  'independence: builder-rationale-and-peer-review-excluded' > "$temp_package/manifest.yaml"

mv "$temp_package" "$package_dir"
trap - EXIT
printf '%s\n' "Review package created: $package_dir"
