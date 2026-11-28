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
  set -euo pipefail
  gleam format --check .
  gleam run -m glinter
  gleam check
  gleam build --warnings-as-errors
  gleam test
  python3 scripts/verify-gleam-docs.py --examples
  bash scripts/verify-readme.sh

verify-examples:
  python3 scripts/verify-gleam-docs.py --examples

verify-readme:
  bash scripts/verify-readme.sh

# Print the canonical content for the README's auto-generated tables.
# Pipe / paste the output into `README.md` between the matching
# BEGIN/END markers (the drift test in `test/readme_drift_test.gleam`
# runs in CI and fails if the README falls out of sync with the
# source-of-truth functions in `yabase/core/encoding`).
gen-readme:
  gleam run -m gen_readme

ci: deps check

# Mutation testing of every module, failing on survivors the baseline lacks.
# Slow: run it on a machine with many cores, then `just mutation-record`.
mutation workers="8":
  gleam run -m metamon/mutation -- run --workers {{workers}}
  gleam run -m metamon/mutation -- gate

# Record the last full mutation run as the baseline and refresh doc/testing.md
mutation-record:
  gleam run -m metamon/mutation -- baseline

# Line coverage of the Erlang test run, written to build/coverage/lcov.info
coverage:
  gleam build --target erlang
  gleam run -m metamon/mutation -- coverage

clean:
  gleam clean
