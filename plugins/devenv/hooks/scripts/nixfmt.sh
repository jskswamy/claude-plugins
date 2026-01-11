#!/bin/bash
set -euo pipefail

# Read tool input from stdin
input=$(cat)

# Extract file path from tool_input
file_path=$(echo "$input" | jq -r '.tool_input.file_path // .tool_input.filePath // ""')

# Only run on flake.nix files
if [[ "$file_path" == *"flake.nix" ]]; then
  if command -v nix-shell &> /dev/null; then
    nix-shell -p nixfmt-rfc-style --run "nixfmt \"$file_path\"" 2>&1 || true
    echo '{"continue": true, "systemMessage": "Formatted flake.nix with nixfmt"}'
  else
    echo '{"continue": true, "systemMessage": "nix-shell not available, skipping nixfmt"}'
  fi
else
  echo '{"continue": true}'
fi
