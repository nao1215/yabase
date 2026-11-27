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

## Mutation testing

`gleam run -m metamon/mutation` changes one operator, `!` or boolean literal in a module under `src/` at a time and runs `gleam test --target erlang` on each change. `.github/workflows/mutation.yml` mutates the modules a pull request or push changes and fails on a survivor that `doc/mutation/baseline.json` does not list; the weekly run mutates every module. `just mutation` runs it locally and `just mutation-record` records the baseline. The score is (killed + timed out) / (killed + timed out + lived). Some mutants loop forever and allocate until the machine runs out of memory; a test run stopped by an out-of-memory killer exits like a passing one, so run locally with `ERL_FLAGS="+hmax 268435456 +hmaxk true"`, which stops a process above 2 GiB of heap and counts the mutant as killed.

The first run (2026-11-27) scored 88.2% with 42 survivors, three of them looping mutants stopped by the out-of-memory killer. Tests were then added for error positions after whitespace, CR LF and padding in Base45, Base91 and Base64Dq, the length reported for a lone final Ascii85 character after `z`, `y` or CR LF, the largest two- and three-symbol Base45 groups, Base91 vectors at the queue boundaries computed with the reference algorithm, a lone Base32 data character before padding, Base58Check version 255, the first and last HRP characters of Bech32 and the index of an invalid one, and the bit size of large unaligned input, and the score rose to 94.7%. The 19 survivors left change nothing on Erlang:

- Positions passed to the invalid-character error (5): the Base91 decoder and the big-number digit reader pass a character position that the error ignores; it is computed again from the byte offset.
- Checks that only run on JavaScript (6): the integer range check of the integer codecs is a no-op on Erlang (3), a remainder in SHA-256 is never negative on Erlang and its sums never land on an exact multiple of 2^32 in the tests (2), and the high word of the SHA-256 length is 0 for any input below 512 MiB, either way (1).
- ASCII fast paths (4): a non-ASCII character never starts with byte 128, and the fast path and the general path count the same length.
- The number of digits per limb in the big-number codecs (3): any limb size gives the same digits on Erlang, whose integers do not overflow.
- Emitting a bit group as soon as it is full or one byte later (1), which gives the same symbols.

<!-- mutation:start -->
| Module | Killed | Lived | Timed out | Score |
|---|---:|---:|---:|---:|
| `yabase` | 323 | 16 | 1 | 95.3% |
| `yabase/internal/sha256` | 13 | 3 | 0 | 81.3% |
| all | 336 | 19 | 1 | 94.7% |
<!-- mutation:end -->

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
