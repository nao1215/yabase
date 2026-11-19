# Testing

`just ci` runs everything below except the nightly job and mutation testing. Tests run on Erlang/OTP 26 to 28 with the Gleam floor (1.15.0) and on OTP 29 with the latest Gleam 1.x, and on the JavaScript target with Node 18 and the current LTS.

## Examples and unit tests

Every encoding has a test file under `test/` with the published test vectors (RFC 4648, RFC 9285, BIP-173 / BIP-350, Z85, the NIST SHA-256 vectors) and its error cases: invalid characters, padding and lengths, sub-byte input and empty input. `test/readme_drift_test.gleam` keeps the multibase prefix table in the README in sync with the code, and each fixed bug keeps its reproduction in a `test/regression_*_test.gleam` file.

## Generated properties

`test/yabase_metamon_test.gleam` uses metamon: `decode(encode(data)) == Ok(data)` for every encoding, through the unified dispatcher and through multibase prefixes.

## Differential testing

`test/differential_test.gleam` compares yabase with independent implementations of the same specifications on random byte strings of 0 to 70 bytes (every padding case): standard, unpadded, URL-safe and URL-safe unpadded Base64 and Base16 must produce the same text as gleam_stdlib's `bit_array` encoders and decode what they produce. On Erlang, the SHA-256 used for the base58check checksum must equal `crypto:hash(sha256, _)` for messages of 0 to 200 bytes, which crosses the 55/56/64-byte lengths where the padding spills into a second block.

## Nightly runs

`.github/workflows/nightly-property.yml` runs the whole suite ten times with `METAMON_RUNS_MULTIPLIER=10`, each pass with a new seed. A failure report prints its seed, so the case can be replayed with `metamon.with_seed` and kept as a regression test.

## Mutation testing

There is no mutation testing tool for Gleam, so `gleam_mutate.py` (from the mutation-testing lab in nao1215/debimate) is run by hand on a copy of the project. It rewrites one operator or boolean result at a time and runs `gleam test` on the Erlang target; a mutant that makes the suite hang past 60 seconds counts as killed. For this run the script also mutated integer comparisons and `+` / `-`. The score is killed / (killed + lived).

MUTATION_TABLE
