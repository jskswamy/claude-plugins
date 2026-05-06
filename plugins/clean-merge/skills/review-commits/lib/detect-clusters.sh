#!/bin/bash
# detect-clusters.sh: flag contiguous-commit feature clusters in $base..HEAD.
# Usage: detect-clusters.sh <base-sha>
# Output: one line per cluster, space-separated short-hashes oldest-first.
set -euo pipefail
base="$1"
MIN_CLUSTER_SIZE=4

mapfile -t hashes < <(git rev-list --reverse "$base..HEAD")

# For each commit, compute its 3-level path prefix from the changed files.
# If any file has fewer than 3 path components, OR files don't all share
# the same 3-level prefix, return empty (commit doesn't fit a cluster).
prefix_of() {
  local h="$1"
  local files
  mapfile -t files < <(git diff-tree --no-commit-id --name-only -r "$h")
  if [[ ${#files[@]} -eq 0 ]]; then
    echo ""
    return
  fi
  local first_prefix
  first_prefix=$(echo "${files[0]}" | awk -F/ 'NF>=3 {print $1"/"$2"/"$3}')
  if [[ -z "$first_prefix" ]]; then
    echo ""
    return
  fi
  for f in "${files[@]}"; do
    local p
    p=$(echo "$f" | awk -F/ 'NF>=3 {print $1"/"$2"/"$3}')
    if [[ "$p" != "$first_prefix" ]]; then
      echo ""
      return
    fi
  done
  echo "$first_prefix"
}

# Walk hashes, group contiguous runs sharing the same non-empty prefix.
clusters=()
current_prefix=""
current_run=()

flush() {
  if [[ ${#current_run[@]} -ge $MIN_CLUSTER_SIZE ]]; then
    local short_run=()
    for h in "${current_run[@]}"; do
      short_run+=("$(git rev-parse --short "$h")")
    done
    clusters+=("${short_run[*]}")
  fi
  current_run=()
  current_prefix=""
}

for h in "${hashes[@]}"; do
  p=$(prefix_of "$h")
  if [[ -z "$p" ]]; then
    flush
    continue
  fi
  if [[ "$p" != "$current_prefix" ]]; then
    flush
    current_prefix="$p"
  fi
  current_run+=("$h")
done
flush

for c in "${clusters[@]}"; do
  echo "$c"
done
