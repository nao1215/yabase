#!/usr/bin/env bash
set -euo pipefail

cleanup() {
  rm -f src/yabase/readme_snippet_*_.gleam
}
trap cleanup EXIT

# Extract each ```gleam block from README.md as a separate module.
# Blocks containing "pub fn" are kept as-is (complete modules).
# Bare expression blocks are wrapped in a function.
n=0
in_block=false
tmp=""
while IFS= read -r line; do
  if [[ "$line" == '```gleam' ]]; then
    in_block=true
    n=$((n + 1))
    tmp=""
    continue
  fi
  if [[ "$line" == '```' ]] && $in_block; then
    in_block=false
    f="src/yabase/readme_snippet_${n}_.gleam"
    if echo "$tmp" | grep -Eq '^[[:space:]]*(pub )?fn '; then
      echo "$tmp" > "$f"
    else
      # Separate import lines from body
      imports=$(echo "$tmp" | grep -E '^[[:space:]]*import ' || true)
      body=$(echo "$tmp" | grep -Ev '^[[:space:]]*import ' || true)
      {
        echo "$imports"
        echo "pub fn readme_${n}_() {"
        echo "$body"
        echo "}"
      } > "$f"
    fi
    continue
  fi
  if $in_block; then
    tmp="${tmp}${line}
"
  fi
done < README.md

gleam build --warnings-as-errors 2>&1
echo "README snippets OK"
