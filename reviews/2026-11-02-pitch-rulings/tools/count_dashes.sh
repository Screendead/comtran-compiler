#!/bin/sh
# Usage: sh tools/count_dashes.sh <repository root>
# Counts the em dashes left in the language definition by W2 (merge 2cf337f).
set -eu
cd "$1"
M=2cf337f
DEF=docs/comtran-language-definition.md
echo "W2 merge: $(git rev-parse $M)"
echo "headings holding an em dash: $(git show $M:$DEF | grep -c -E '^#{1,6} .*—')"
echo "contents lines holding an em dash: $(git show $M:$DEF | grep -c -E '^\s*[-*0-9.]+ .*\[.*—.*\]\(#')"
echo "em dashes before W2 ($M^1): $(git show $M^1:$DEF | grep -o '—' | wc -l | tr -d ' ')"
echo "em dashes after W2 ($M): $(git show $M:$DEF | grep -o '—' | wc -l | tr -d ' ')"
echo "headings:"
git show $M:$DEF | grep -n -E '^#{1,6} .*—'
