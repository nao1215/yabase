#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
# Sizes are original bytes; the decode timer excludes encode and compilation.
# YB_CASE can also run an individual case via `gleam run -m yabase_bench`.
for target in erlang javascript; do
  for codec in base2 base16 base32 base64 z85 rfc1924 ascii85 adobe base45 base91 dq; do
    for size in 10000 100000; do
      mise trust -q . ; eval "$(mise env -s bash)"
      printf '%s ' "$target"
      YB_CASE="$codec-dec-$size" timeout 90 gleam run --target "$target" -m yabase_bench
    done
  done
done
