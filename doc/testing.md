# Testing

`just ci` checks formatting, lint, the Erlang build, tests, examples and README
code blocks. Run `gleam build --target javascript --warnings-as-errors` and
`gleam test --target javascript` for the second target. CI also exercises Gleam
1.15.0 on OTP 26, 27 and 28, the latest Gleam 1.x on OTP 29, and Node 18 and LTS.

## Vectors and regression tests

Codec tests use fixed outputs from RFC 4648, RFC 9285, BIP 173, BIP 350, Z85 and
NIST SHA-256 vectors. They cover empty inputs, leading zero bytes, padding,
checksums, malformed characters and metadata. Byte codecs retain large-payload
tests, while integer tests check canonical spelling and each target's limits.

The `regression_*_test.gleam` files test original-input diagnostics, validation
order, metadata mismatches, whole-byte admission and registry coverage. Short
literal inputs fix each expected grapheme and index, including combined Unicode
characters, CRLF, trimmed whitespace and multibase prefixes. The alignment
matrix covers every encoding selection and all supported multibase paths.

## Independent oracles

`regression_wire_fixture_test.gleam` compares hexadecimal and the four ASCII
Base64 encoders against literal outputs computed with Python's standard library.
The corpus contains every possible single byte and additional empty, padded,
leading-zero and multibyte inputs. These fixtures remain independent after the
encoders delegate to `gleam_stdlib`.

`differential_test.gleam` retains comparisons with `gleam_stdlib` for encoding
compatibility and decoding. For delegated encoders, those comparisons alone are
not an independent implementation oracle. On Erlang, SHA-256 is also compared
with `crypto:hash(sha256, _)` across block-padding boundaries. Base58Check and
Bech32 regression tests use fixed checksum vectors computed independently of
the package's encoder.

## Generated properties

`yabase_metamon_test.gleam` exercises byte round trips through `Encoding` and
multibase. A round trip complements fixed vectors: two functions can agree on
the same incorrect representation, so it does not replace an independent
expected output.

`.github/workflows/nightly-property.yml` repeats the suite with
`METAMON_RUNS_MULTIPLIER=10` and fresh seeds. Keep a failing input as a regression
case and use the reported seed to reproduce a property failure.

## README checks

`readme_drift_test.gleam` verifies one generated table with all 23 accepted
multibase prefixes. `just gen-readme` prints the table from the public registry.
`scripts/verify-readme.sh` checks fenced Gleam examples in a temporary consumer
and rejects empty discovery and incomplete fences. Example programs remain
under `examples/`; `just verify-examples` compiles them and runs each `main` on both targets.

## Historical mutation testing

The following results describe the pre-refactor source on 2026-11-19. They are
not coverage measurements of the current API. A local `gleam_mutate.py` script
changed operators and Boolean results and ran the Erlang tests; timed-out
mutants counted as killed. The score was killed / (killed + lived).

| Run | Killed | Lived | Score |
|-----|-------:|------:|------:|
| Initial suite | 308 | 135 | 69.5% |
| After error-position assertions | 360 | 79 | 82.0% |

That exercise exposed incorrect Ascii85 error positions after whitespace,
fixed in #119. Keep position assertions when reorganizing codec internals;
changing a reported index must affect a test that observes the public error.
