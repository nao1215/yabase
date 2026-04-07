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

test:
  gleam test

docs:
  gleam docs build

check:
  gleam format --check .
  gleam check
  gleam build --warnings-as-errors
  gleam test
  @just verify-examples
  @just verify-readme

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

ci: deps check

clean:
  gleam clean
