#!/bin/bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/helpers.sh"
SCRIPT="$SCRIPT_DIR/../lib/detect-clusters.sh"

tmp=$(mktemp -d); trap "rm -rf $tmp" EXIT
mk_repo "$tmp/repo"
cd "$tmp/repo"
base=$(git rev-parse HEAD)

# 4 commits all under plugins/foo/skills/bar/ → one cluster
mkdir -p plugins/foo/skills/bar
echo a > plugins/foo/skills/bar/a; git add . && git -c user.email=t@t -c user.name=t commit -q -m "Add a"
ha=$(git rev-parse --short HEAD)
echo b > plugins/foo/skills/bar/b; git add . && git -c user.email=t@t -c user.name=t commit -q -m "Add b"
hb=$(git rev-parse --short HEAD)
echo c > plugins/foo/skills/bar/c; git add . && git -c user.email=t@t -c user.name=t commit -q -m "Add c"
hc=$(git rev-parse --short HEAD)
echo d > plugins/foo/skills/bar/d; git add . && git -c user.email=t@t -c user.name=t commit -q -m "Add d"
hd=$(git rev-parse --short HEAD)

out=$(bash "$SCRIPT" "$base")
assert_eq "$out" "$ha $hb $hc $hd" "single 4-commit cluster"

# Add a 5th commit that breaks the cluster (different prefix)
mkdir -p plugins/other
echo z > plugins/other/z; git add . && git -c user.email=t@t -c user.name=t commit -q -m "Add z"
out=$(bash "$SCRIPT" "$base")
# original cluster of 4 should still be detected, new 5th commit excluded
assert_eq "$out" "$ha $hb $hc $hd" "cluster preserved despite trailing outlier"

# Add 4 more under a different prefix → 2 clusters now
mkdir -p plugins/other/skills/baz
echo p > plugins/other/skills/baz/p; git add . && git -c user.email=t@t -c user.name=t commit -q -m "Add p"
hp=$(git rev-parse --short HEAD)
echo q > plugins/other/skills/baz/q; git add . && git -c user.email=t@t -c user.name=t commit -q -m "Add q"
hq=$(git rev-parse --short HEAD)
echo r > plugins/other/skills/baz/r; git add . && git -c user.email=t@t -c user.name=t commit -q -m "Add r"
hr=$(git rev-parse --short HEAD)
echo s > plugins/other/skills/baz/s; git add . && git -c user.email=t@t -c user.name=t commit -q -m "Add s"
hs=$(git rev-parse --short HEAD)

out=$(bash "$SCRIPT" "$base")
expected="$ha $hb $hc $hd
$hp $hq $hr $hs"
assert_eq "$out" "$expected" "two distinct clusters"

# Test the minimum-size threshold: 3 contiguous commits should NOT cluster
mk_repo "$tmp/repo2"
cd "$tmp/repo2"
base2=$(git rev-parse HEAD)
mkdir -p plugins/foo/skills/bar
for i in 1 2 3; do
  echo $i > plugins/foo/skills/bar/$i
  git add . && git -c user.email=t@t -c user.name=t commit -q -m "Add $i"
done
out=$(bash "$SCRIPT" "$base2")
assert_eq "$out" "" "3 commits do not form a cluster (minimum 4)"

echo "PASS"
