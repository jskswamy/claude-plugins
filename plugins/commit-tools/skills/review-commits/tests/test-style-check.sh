#!/bin/bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/helpers.sh"
SCRIPT="$SCRIPT_DIR/../lib/style-check.sh"

tmp=$(mktemp -d); trap "rm -rf $tmp" EXIT
classic="$tmp/classic.md"
conv="$tmp/conventional.md"
cat > "$classic" <<'STYLE'
---
name: classic
---
STYLE
cat > "$conv" <<'STYLE'
---
name: conventional
---
STYLE

# classic: capitalized, no period, ≤72
assert_exit "bash $SCRIPT 'Add foo to bar' '$classic'" 0 "valid classic"
assert_exit "bash $SCRIPT 'add foo to bar' '$classic'" 1 "classic must capitalize"
assert_exit "bash $SCRIPT 'Add foo to bar.' '$classic'" 1 "classic no trailing period"
long=$(printf 'A%.0s' {1..73})
assert_exit "bash $SCRIPT '$long' '$classic'" 1 "classic ≤72 chars"

# conventional: type(scope)?: description, lowercase
assert_exit "bash $SCRIPT 'feat: add x' '$conv'" 0 "valid conventional no scope"
assert_exit "bash $SCRIPT 'feat(api): add x' '$conv'" 0 "valid conventional with scope"
assert_exit "bash $SCRIPT 'add x' '$conv'" 1 "conventional needs type"
assert_exit "bash $SCRIPT 'Feat: add x' '$conv'" 1 "conventional lowercase"
assert_exit "bash $SCRIPT 'banana: add x' '$conv'" 1 "conventional unknown type"

echo "PASS"
