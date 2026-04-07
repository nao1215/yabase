#!/usr/bin/env bash
set -euo pipefail

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
    if echo "$tmp" | grep -q "^pub fn \|^fn "; then
      echo "$tmp" > "$f"
    else
      # Separate import lines from body
      imports=$(echo "$tmp" | grep "^import " || true)
      body=$(echo "$tmp" | grep -v "^import " || true)
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

result=0
gleam build --warnings-as-errors 2>&1 || result=$?
rm -f src/yabase/readme_snippet_*_.gleam
if [ $result -ne 0 ]; then
  echo "ERROR: README code snippets failed to compile (or have warnings)"
  exit 1
fi
echo "README snippets OK"
