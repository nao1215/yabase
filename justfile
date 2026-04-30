set shell := ["bash", "-cu"]

default:
  @just --list

deps:
  gleam deps download

format:
  gleam format

format-check:
  gleam format --check .

typecheck:
  gleam check

build:
  gleam build --warnings-as-errors

lint:
  gleam run -m glinter

test:
  gleam test

docs:
  gleam docs build

check:
  #!/usr/bin/env bash
  gleam format --check .
  gleam run -m glinter
  gleam check
  gleam build --warnings-as-errors
  gleam test
  trap 'rm -f src/yabase/example_*.gleam' EXIT
  for f in examples/*.gleam; do
    mod=$(basename "$f" .gleam)
    cp "$f" "src/yabase/example_${mod}.gleam"
  done
  gleam build
  bash scripts/verify-readme.sh

verify-examples:
  #!/usr/bin/env bash
  trap 'rm -f src/yabase/example_*.gleam' EXIT
  for f in examples/*.gleam; do
    mod=$(basename "$f" .gleam)
    cp "$f" "src/yabase/example_${mod}.gleam"
  done
  gleam build

verify-readme:
  bash scripts/verify-readme.sh

# Print the canonical content for the README's auto-generated tables.
# Pipe / paste the output into `README.md` between the matching
# BEGIN/END markers (the drift test in `test/readme_drift_test.gleam`
# runs in CI and fails if the README falls out of sync with the
# source-of-truth functions in `yabase/core/encoding`).
gen-readme:
  gleam run -m yabase/dev/gen_readme

ci: deps check

clean:
  gleam clean
