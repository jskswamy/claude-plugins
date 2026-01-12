#!/bin/bash
# Hook script to notify about changelog updates when plugin versions change
set -euo pipefail

# Read tool input from stdin
input=$(cat)

# Extract file path from tool input
file_path=$(echo "$input" | jq -r '.tool_input.file_path // .tool_input.filePath // ""')

# Check if the modified file is plugin.json or marketplace.json
if [[ "$file_path" == *"plugin.json" ]] || [[ "$file_path" == *"marketplace.json" ]]; then
  # Check if git-cliff is available
  if command -v git-cliff &> /dev/null; then
    # Count unreleased commits
    unreleased_count=$(git cliff --unreleased --context 2>/dev/null | jq -r '.[0].commits | length' 2>/dev/null || echo "0")

    if [[ "$unreleased_count" -gt 0 ]]; then
      # Determine which plugin was modified (if any)
      plugin_name=""
      if [[ "$file_path" == *"plugins/"*"/plugin.json" ]]; then
        plugin_name=$(echo "$file_path" | sed -n 's|.*plugins/\([^/]*\)/.*|\1|p')
      fi

      if [[ -n "$plugin_name" ]]; then
        message="Plugin '$plugin_name' version updated. $unreleased_count unreleased commit(s). Run 'git cliff --include-path \"plugins/$plugin_name/**/*\" -o plugins/$plugin_name/CHANGELOG.md' to update plugin changelog."
      else
        message="Marketplace/plugin config updated. $unreleased_count unreleased commit(s). Run 'git cliff -o CHANGELOG.md' to update changelog."
      fi

      echo "{\"continue\": true, \"systemMessage\": \"$message\"}"
    else
      echo '{"continue": true}'
    fi
  else
    echo '{"continue": true, "systemMessage": "git-cliff not available. Enter nix develop to enable changelog generation."}'
  fi
else
  echo '{"continue": true}'
fi
