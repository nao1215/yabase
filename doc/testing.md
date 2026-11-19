# Testing

`just ci` runs everything below except the nightly job and mutation testing. Tests run on Erlang/OTP 26 to 28 with the Gleam floor (1.15.0) and on OTP 29 with the latest Gleam 1.x, and on the JavaScript target with Node 18 and the current LTS.

## Examples and unit tests

Every encoding has a test file under `test/` with the published test vectors (RFC 4648, RFC 9285, BIP-173 / BIP-350, Z85, the NIST SHA-256 vectors) and its error cases: invalid characters, padding and lengths, sub-byte input and empty input. `test/readme_drift_test.gleam` keeps the multibase prefix table in the README in sync with the code, each fixed bug keeps its reproduction in a `test/regression_*_test.gleam` file, and `test/error_position_test.gleam` pins the position every decoder reports for an invalid character.

## Generated properties

`test/yabase_metamon_test.gleam` uses metamon: `decode(encode(data)) == Ok(data)` for every encoding, through the unified dispatcher and through multibase prefixes.

## Differential testing

`test/differential_test.gleam` compares yabase with independent implementations of the same specifications on random byte strings of 0 to 70 bytes (every padding case): standard, unpadded, URL-safe and URL-safe unpadded Base64 and Base16 must produce the same text as gleam_stdlib's `bit_array` encoders and decode what they produce. On Erlang, the SHA-256 used for the base58check checksum must equal `crypto:hash(sha256, _)` for messages of 0 to 200 bytes, which crosses the 55/56/64-byte lengths where the padding spills into a second block.

## Nightly runs

`.github/workflows/nightly-property.yml` runs the whole suite ten times with `METAMON_RUNS_MULTIPLIER=10`, each pass with a new seed. A failure report prints its seed, so the case can be replayed with `metamon.with_seed` and kept as a regression test.

## Mutation testing

There is no mutation testing tool for Gleam, so `gleam_mutate.py` (from the mutation-testing lab in nao1215/debimate) is run by hand on a copy of the project. It rewrites one operator or boolean result at a time and runs `gleam test` on the Erlang target; a mutant that makes the suite hang past 60 seconds counts as killed. For this run the script also mutated integer comparisons and `+` / `-`. The score is killed / (killed + lived).

| Date | Files | Killed | Lived | Score |
|---|---|---:|---:|---:|
| 2026-11-19, first run | every module under `src/` with mutants (443) | 308 | 135 | 69.5% |
| 2026-11-19, after `test/error_position_test.gleam` | same (439 after the ascii85 fix) | 360 | 79 | 82.0% |

The first run showed that almost no test pinned the `position` in `InvalidCharacter`: turning `pos + 1` into `pos - 1` survived in every decoder. Checking those positions found a bug, fixed in #119: `ascii85` and `adobe_ascii85` reported every position after whitespace inside a group one character too early per whitespace character. `test/error_position_test.gleam` now pins the position for every decoder, after every kind of skipped whitespace and after the `z` / `y` shortcuts. The survivors, grouped:

- `bech32` (16): the HRP character range checks at their exact bounds, `check_tail_zero` for padding bits the encoder never produces, and the separator search from the end.
- `base64/dq` (13), `base64/standard` (7) and `base64/urlsafe` (8): positions in branches that the alphabet check run before decoding makes unreachable for any character except a misplaced `=`.
- `internal/sha256` (7): equivalent mutants; the bit loop stops at a power of two that never equals `0xFFFFFFFF`, `mask32` treats 0 the same on either branch, and the 65th schedule word is never read.
- `base91` (6), `base45` (4), `base32/*` (6) and the base85 variants (9): positions after the first group in rarer layouts, the trailing zero bytes of a padded final group (`+ 0` and `- 0` are the same), and an unused `encode_u32` helper branch.
- `core/encoding` (2): `is_javascript_safe` at its exact bound.
