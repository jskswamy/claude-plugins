#!/bin/bash
# Usage: style-check.sh <subject> <style-file>
# Exit 0 if subject conforms; print reason + exit 1 otherwise.
set -euo pipefail
subject="$1"
style_file="$2"

style_name=$(awk '/^name:/{print $2; exit}' "$style_file")

case "$style_name" in
  classic)
    [[ ${#subject} -le 72 ]] || { echo "subject >72 chars"; exit 1; }
    [[ "$subject" =~ ^[A-Z] ]] || { echo "subject must start uppercase"; exit 1; }
    [[ "$subject" != *. ]] || { echo "subject has trailing period"; exit 1; }
    ;;
  conventional)
    [[ ${#subject} -le 72 ]] || { echo "subject >72 chars"; exit 1; }
    [[ "$subject" =~ ^(feat|fix|docs|style|refactor|perf|test|build|ci|chore|revert)(\([a-z0-9_-]+\))?!?:\ .+ ]] \
      || { echo "subject does not match conventional format"; exit 1; }
    ;;
  *)
    echo "unknown style: $style_name"; exit 2 ;;
esac
exit 0
