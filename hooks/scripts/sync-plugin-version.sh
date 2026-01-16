#!/bin/bash
# Hook script to auto-sync plugin versions when content changes
# Bumps patch version in plugin.json and syncs to marketplace.json
set -euo pipefail

# Read tool input from stdin
input=$(cat)

# Extract file path from tool input
file_path=$(echo "$input" | jq -r '.tool_input.file_path // .tool_input.filePath // ""')

# Check if file is in a plugin directory
if [[ "$file_path" != *"plugins/"* ]]; then
  echo '{"continue": true}'
  exit 0
fi

# Extract plugin name from path
plugin_name=$(echo "$file_path" | sed -n 's|.*plugins/\([^/]*\)/.*|\1|p')

if [[ -z "$plugin_name" ]]; then
  echo '{"continue": true}'
  exit 0
fi

# Skip if editing metadata files (avoid loops)
if [[ "$file_path" == *"plugin.json" ]] || [[ "$file_path" == *"marketplace.json" ]]; then
  echo '{"continue": true}'
  exit 0
fi

# Skip non-content files
if [[ "$file_path" == *"README.md" ]] || [[ "$file_path" == *"CHANGELOG.md" ]]; then
  echo '{"continue": true}'
  exit 0
fi

# Skip .claude-plugin directory
if [[ "$file_path" == *".claude-plugin/"* ]]; then
  echo '{"continue": true}'
  exit 0
fi

# Check session marker to avoid multiple bumps
marker="/tmp/.claude-version-bumped-$plugin_name"
if [[ -f "$marker" ]]; then
  echo '{"continue": true}'
  exit 0
fi

# Paths to config files
plugin_json="plugins/$plugin_name/.claude-plugin/plugin.json"
marketplace_json=".claude-plugin/marketplace.json"

# Verify plugin.json exists
if [[ ! -f "$plugin_json" ]]; then
  echo '{"continue": true}'
  exit 0
fi

# Get current version
current_version=$(jq -r '.version' "$plugin_json")

if [[ -z "$current_version" ]] || [[ "$current_version" == "null" ]]; then
  echo '{"continue": true}'
  exit 0
fi

# Bump patch version
IFS='.' read -r major minor patch <<< "$current_version"
new_version="$major.$minor.$((patch + 1))"

# Update plugin.json
jq --arg v "$new_version" '.version = $v' "$plugin_json" > "${plugin_json}.tmp"
mv "${plugin_json}.tmp" "$plugin_json"

# Update marketplace.json if plugin exists there
if [[ -f "$marketplace_json" ]]; then
  # Check if plugin exists in marketplace
  plugin_exists=$(jq --arg name "$plugin_name" '.plugins[] | select(.name == $name) | .name' "$marketplace_json" 2>/dev/null || echo "")

  if [[ -n "$plugin_exists" ]]; then
    jq --arg name "$plugin_name" --arg v "$new_version" \
      '(.plugins[] | select(.name == $name)).version = $v' \
      "$marketplace_json" > "${marketplace_json}.tmp"
    mv "${marketplace_json}.tmp" "$marketplace_json"
  fi
fi

# Create session marker
touch "$marker"

# Output success message
echo "{\"continue\": true, \"systemMessage\": \"Auto-bumped $plugin_name to v$new_version\"}"
