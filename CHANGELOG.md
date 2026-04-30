# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/),
and this project adheres to [Semantic Versioning](https://semver.org/).

## [Unreleased]

## [0.12.0] - 2026-04-30

### Added

- **JavaScript-target test lane in CI.** CI now runs `gleam test
  --target javascript` against Node.js, exercising the public codec
  surface on JS instead of merely confirming it compiles. The release
  workflow runs the same JS test step before publishing to Hex so the
  release matrix matches CI. (#42)
- **Minimum-supported Node compatibility lane.** The CI and release
  JavaScript matrix now also runs against Node 18 — the support
  floor documented in the README — in addition to the latest-LTS
  lane on Node 22. The two lanes are commented as "support floor"
  and "convenience coverage" so future bumps are intentional. (#47)
- **README's multibase prefix table is now generated from source.**
  The hand-maintained "Multibase prefix coverage" table is replaced
  by a fenced section between `<!-- BEGIN: multibase-prefix-table -->`
  and `<!-- END: multibase-prefix-table -->` whose content is derived
  from `encoding.multibase_prefix`, `encoding.from_multibase_prefix`,
  and `encoding.multibase_name`. A new `test/readme_drift_test.gleam`
  fails CI if the README falls out of sync with the source-of-truth
  functions, and `just gen-readme` (or `gleam run -m yabase/dev/gen_readme`)
  prints the canonical content for paste-update. (#46)
- **Target capability helpers on `yabase/core/encoding`.** New public
  surface lets callers branch on JavaScript safety programmatically
  instead of scraping README caveats:
  - `Target` opaque type with `target_erlang/0` and
    `target_javascript/0` smart constructors
  - `is_javascript_safe(enc: Encoding) -> Bool` — `False` for the
    bignum-backed codecs (`base8`, `base10`, `base32` Crockford /
    CrockfordCheck, `base36`, `base58` Bitcoin / Flickr, `base62`)
    that lose precision past `Number.MAX_SAFE_INTEGER`, `True` for
    every other encoding
  - `supports_target(enc: Encoding, target: Target) -> Bool` —
    always `True` for `target_erlang()`, delegates to
    `is_javascript_safe` for `target_javascript()`
  Useful after `multibase.decode` auto-detects an `Encoding` from a
  prefix supplied by an untrusted source: callers can reject codecs
  the JavaScript target cannot represent without listing them by
  hand. README has a worked dynamic-selection example. (#43)

### Changed

- **JS-target-limited tests are explicitly isolated**, not silently
  skipped. Tests that exercise codecs whose internals rely on
  arbitrary-precision integer arithmetic (base32 Crockford, base58,
  base58check, base36, and the matching multibase prefixes) and
  the `intid` `*_above_cap_test` variants on `int64_max + 1` are
  marked `@target(erlang)`. They remain covered on BEAM and are
  intentionally excluded on JavaScript, where 53-bit `Number`
  precision cannot represent the inputs. The README "Supported
  targets" section documents this policy. (#42)
- **`Decoded` is now `pub opaque type` (BREAKING)**. The
  `multibase.decode/1` (and `yabase.decode_multibase/1`) result is
  still a `Decoded` value, but external callers can no longer pattern
  match on the `Decoded(encoding:, data:)` constructor. Use the new
  accessors instead:
  - `encoding.decoded_encoding(decoded: Decoded) -> Encoding`
  - `encoding.decoded_data(decoded: Decoded) -> BitArray`
  Code that previously wrote
  `let assert Ok(Decoded(encoding: enc, data: payload)) = decode_multibase(...)`
  becomes
  `let assert Ok(d) = decode_multibase(...); let enc = encoding.decoded_encoding(d); let payload = encoding.decoded_data(d)`.
  Tests that only consume the bytes can use `multibase.decode_bytes/1`,
  which returns `Result(BitArray, CodecError)` directly. README and
  `examples/multibase_auto_detect.gleam` are updated. (#45)

## [0.11.0] - 2026-04-30

### Added

- **Strict-canonical decoders for base64 and base32**, opting into the
  RFC 4648 §3.5 rejection of non-canonical encodings (where pad bits
  in a final partial block are non-zero). New surface:
  - `yabase/base64/standard.decode_strict/1` — same shape as `decode/1`
    but returns `Error(NonCanonical)` when the trailing pad bits are
    set
  - `yabase/base32/rfc4648.decode_strict/1` — same shape, with the
    canonical re-encoding compared case-insensitively
  - `yabase/facade.decode_base64_strict/1` and `decode_base32_strict/1`
    re-export the above on the high-level API
  - new `NonCanonical` variant on `CodecError` (minor API
    addition — exhaustive case statements over `CodecError` need a new
    arm)
  Useful for signature verification, content-addressable storage, and
  any audit-style use case where the wire encoding's uniqueness is
  part of the contract. The lenient `decode/1` paths are unchanged
  for backwards compatibility. (#39)

## [0.10.0] - 2026-04-28

### Changed

- **`Encoding` and variant ADTs are now `pub opaque type` (BREAKING)**.
  `Encoding`, `Base32Variant`, `Base58Variant`, `Base64Variant`, and
  `Base85Variant` no longer expose their constructors to package-
  external callers. Code that previously wrote `Base32(RFC4648)` or
  pattern-matched `case enc { Base64(_) -> ... }` will not compile;
  switch construction sites to the smart constructors added in
  v0.9.0 (`encoding.base32_rfc4648()`, `encoding.base64_standard()`,
  …) and replace pattern matches with field access on `Decoded`
  (the `encoding` and `data` fields stay public). Adding a new
  alphabet is now a non-breaking minor instead of a SemVer-major.
  (#32)
- **`yabase/core/dispatcher` removed**. Its `encode/2` and
  `decode_as/2` move into `yabase/core/encoding` (and stay reachable
  via the existing top-level `yabase.encode/2` / `yabase.decode/2`
  facade). External callers using the top-level facade are
  unaffected; callers that imported `yabase/core/dispatcher` directly
  switch to `yabase/core/encoding`. (#32)
- **`CodecError` and Bech32 / Base58Check result types moved to
  `yabase/core/error`**. `import yabase/core/encoding.{type CodecError}`
  keeps working through a type alias, but the constructor
  short-imports (`InvalidCharacter`, `InvalidLength`, `Overflow`,
  `Bech32Decoded`, …) only resolve from `yabase/core/error` now.
  Update import lines accordingly. (#32)

## [0.9.0] - 2026-04-28

### Added

- 25 smart constructors on `yabase/core/encoding` — one per existing
  `Encoding` variant: `base2/0`, `base8/0`, `base10/0`, `base16/0`,
  `base32_rfc4648/0`, `base32_hex/0`, `base32_crockford/0`,
  `base32_crockford_check/0`, `base32_clockwork/0`,
  `base32_z_base32/0`, `base36/0`, `base45/0`, `base58_bitcoin/0`,
  `base58_flickr/0`, `base62/0`, `base64_standard/0`,
  `base64_url_safe/0`, `base64_no_padding/0`,
  `base64_url_safe_no_padding/0`, `base64_dq/0`, `base85_btoa/0`,
  `base85_adobe/0`, `base85_rfc1924/0`, `base85_z85/0`, `base91/0`.
  Each returns the same `Encoding` value as the matching ADT
  constructor (`encoding.base32_rfc4648() == Base32(RFC4648)`), but
  the smart-constructor signature stays stable across releases even
  if the underlying variant ADT changes shape. New 25-test smoke
  module pins that equivalence so a future opaque migration can
  refactor the ADT freely. (#32, partial)

### Notes

- This is the non-breaking first half of #32. The full plan is to
  promote `Encoding` (and `Base32Variant` / `Base58Variant` /
  `Base64Variant` / `Base85Variant`) to `pub opaque type` so external
  callers cannot pattern-match on the constructor list at all. That
  step is BREAKING for any caller that today writes
  `case enc { Base64(_) -> ... }` outside the package, and it
  requires moving the dispatcher and multibase-prefix tables out of
  the `core/dispatcher` and `core/multibase` modules into the type's
  defining module (so the pattern match stays inside the opaque
  boundary). Tracked as a follow-up — landing the smart constructors
  first lets external callers migrate their construction sites
  (`Base32(RFC4648)` → `encoding.base32_rfc4648()`) on the current
  release without waiting for the bigger refactor.

## [0.8.0] - 2026-04-28

### Added

- JavaScript target compilation. `gleam.toml` no longer pins
  `target = "erlang"`, so the package compiles for both Erlang and
  JavaScript. The four `@external(erlang, "erlang", ...)` calls in
  `base91.gleam` were replaced with the cross-target `gleam/int`
  bitwise helpers (no FFI remains in `src/`). CI now runs a
  `Build (JavaScript)` job that verifies the package compiles
  cleanly under `gleam build --target javascript`. (#31)

### Notes

- The Erlang test suite (647 tests) is unaffected. A subset of the
  encodings (base32 Crockford, base58, base36 — anything that uses
  arbitrary-precision integer arithmetic for the bignum-style codecs)
  rely on BEAM bignum semantics and produce wrong values when run
  on JavaScript past `Number.MAX_SAFE_INTEGER`. Those modules still
  compile on JavaScript but their tests are not yet wired into a
  cross-target test run; partitioning the test suite (or porting the
  bignum codecs to a JS-safe representation) is a separate piece of
  follow-up work. base16, base64, base91, base32 RFC4648 and ascii85
  remain JavaScript-safe.

## [0.7.0] - 2026-04-28

### Added

- `yabase/intid` now exposes a bounded decode family:
  `decode_int_base32_rfc4648_bounded`,
  `decode_int_base32_crockford_bounded`,
  `decode_int_base36_bounded`, `decode_int_base58_bounded`,
  `decode_int_base58_flickr_bounded`, and `decode_int_base62_bounded`.
  Each takes `input:` and `max:` labels and returns
  `Error(Overflow)` when the decoded value exceeds `max`. Two cap
  constants are exported alongside: `intid.int64_max` (`2^63 - 1`,
  the signed 64-bit ceiling that SQLite `INTEGER`, Postgres
  `bigserial`, and MySQL `BIGINT` all share) and
  `intid.int53_max` (`2^53 - 1`, `Number.MAX_SAFE_INTEGER` for the
  JavaScript-target boundary). The existing unbounded `decode_int_*`
  family is unchanged: it still accepts strings of any length and
  returns Erlang's bignum, which is the right behaviour when the
  decoded value stays inside the BEAM. The bounded variants exist
  for the case where the value flows into a fixed-width sink — a
  database integer column or a JS `number` — where an unbounded
  bignum surfaces as a driver crash or a silent precision loss
  rather than as a clear `CodecError`. The error contract is
  otherwise identical: `InvalidLength(0)` for empty input,
  `InvalidCharacter` for alphabet violations, then `Overflow` last
  if the value parsed cleanly but exceeds the cap. (#28)

## [0.6.0] - 2026-04-28

### Fixed

- **internal/sha256**: drop the JavaScript-target compile warning
  ("Truncated bit array segment ... 64-bit long int, but on the
  JavaScript target numbers have at most 52 bits") that fired on
  every clean compile of any project depending on this package
  from the JS target. The previous `<<block:bytes-size(64),
  rest:bits>>` segment pattern was misinterpreted by the compiler
  as a 64-bit integer segment; switch `process_blocks` to use
  `bit_array.slice` so the split is expressed in stdlib terms with
  no segment-pattern parsing. Runtime behaviour is unchanged on
  both targets — `process_blocks` still consumes 64-byte blocks
  in source order and feeds the same SHA-256 compression rounds.
  New regression tests pin the SHA-256 output for 65-byte and
  200-byte inputs (the 65-byte case crosses the block boundary
  exactly once, which is where the warning would have masked any
  real corruption). `Base58Check` and `Bech32` round-trips that
  rely on this SHA-256 inner loop are unaffected. (#20)

### Changed

- **base16 (BREAKING)**: `base16.encode` and `facade.encode_base16`
  now emit canonical uppercase hex (`0-9 A-F`) per RFC 4648 §8.
  The previous lowercase output (`"deadbeef"` for `<<0xde, 0xad,
  0xbe, 0xef>>`) departed from the spec's canonical form and broke
  string-equality comparisons against systems that follow it (HTTP
  Signature, Erlang `crypto:hash`'s default uppercase output, IPFS
  multibase prefix `F`, etc.). Callers who specifically need the
  lowercase variant — `sha256sum` shell output, IPFS multibase
  prefix `f`, JWT implementations that emit lowercase digests —
  should switch to `base16.encode_lowercase` /
  `facade.encode_base16_lowercase`. The decoder remains
  case-insensitive, so round-trips work in both directions. The
  multibase encoder still emits the registry-canonical lowercase
  form under prefix `f` (and would emit uppercase under prefix
  `F`, currently unused on the encode side); only the
  unprefixed `base16.encode` path is affected. (#19)

### Documentation

- `yabase/base32/crockford` makes the bignum-shape semantics loud at
  the module level and on `encode/1`. The encoder treats input as a
  big-endian unsigned integer and emits the base-32 representation
  with leading zeros stripped, so output length varies with the
  numeric magnitude of the input rather than its byte length — 5
  random bytes whose top byte is `0x00` round-trip to a 7-character
  string, not 8. Callers who want fixed-length, byte-aligned Base32
  framing (ULID / NanoID / Stripe-style IDs) should use
  `yabase/base32/rfc4648` instead. The pointer is now in both
  docstrings so a reader scanning either surface sees the choice
  immediately. (#22)

### Added

- `bech32.encode_default(hrp, data)` is a convenience wrapper around
  `bech32.encode(Bech32m, hrp, data)` for application authors who want
  a short, copy-pasteable, error-resistant ID with a custom HRP and
  don't need to choose between BIP 173 and BIP 350. The default is
  `Bech32m` (BIP 350) — the strict-checksum variant that every
  non-SegWit-v0 use case should prefer. The variant-explicit
  `encode/3` remains the only correct entry point for SegWit
  witness-program addresses where the caller must distinguish the
  two BIPs. (#21)

## [0.5.0] - 2026-04-27

### Changed

- `bech32.encode` now rejects uppercase or mixed-case HRPs with
  `Error(InvalidHrp("HRP must be lowercase"))` instead of silently
  lowercasing the input. BIP 173 mandates a lowercase HRP, and the
  previous silent normalization could mask bugs where the HRP was used
  as a key or identifier elsewhere (the caller passed `"BC"` but the
  emitted address — and the round-tripped HRP after decode — was
  `"bc"`). **Breaking change** for callers that passed uppercase or
  mixed-case input; lowercase the HRP at the call site if you start from
  a mixed-case identifier. The decoder still accepts an all-uppercase
  Bech32 string as before. (#15)

### Fixed

- `intid.decode_int_*` now reject the empty string with
  `Error(InvalidLength(0))` instead of returning `Ok(0)`. Treating an empty
  input as zero made it impossible for callers to distinguish "no ID was
  supplied" from "the ID is the integer zero", which matters for URL
  routing, form parsing, and database lookups. The byte-oriented decoders
  in `yabase/facade` (e.g. `base62.decode("")`) keep their `Ok(<<>>)`
  round-trip semantics. **Breaking change** for callers that relied on the
  previous `Ok(0)` for empty input — guard the empty case before calling
  `decode_int_*`. (#14)

## [0.4.0] - 2026-04-26

### Added

- New `yabase/intid` module with `encode_int_*` / `decode_int_*`
  helpers for short URL-safe identifier use cases (DB autoincrement
  ids, sequence numbers, hash truncations). Covers Base32 (RFC 4648,
  Crockford), Base36, Base58 (Bitcoin, Flickr), and Base62. Without
  these helpers every caller had to re-implement the same
  `Int -> big-endian bytes -> trim-leading-zero` shim plus the inverse
  for decode (~40 lines per project). `encode_int_*` emits canonical
  form (no leading zero characters); `decode_int_*` is tolerant of
  leading zero characters so externally zero-padded input round-trips
  to the same `Int`. Negative inputs are normalized via
  `int.absolute_value` before encoding. Decode returns
  `Result(Int, CodecError)` to match the rest of the library. (#11)

## [0.3.0] - 2026-04-25

### Fixed

- `decode` for Base64 (Standard, URL-safe, NoPadding, DQ) and
  Base32 (RFC 4648, Hex, Clockwork, z-base-32) now reports
  `InvalidCharacter` with the offending byte and its position when
  the input contains whitespace or other non-alphabet bytes,
  instead of a misleading `InvalidLength` triggered by the
  whitespace shifting the total length off the expected modulus.
  The alphabet check runs before the length check across all of
  these codecs. The behaviour for inputs that genuinely have a
  bad length but only alphabet bytes is unchanged. URL-safe
  no-padding already followed this contract and is unchanged.
  (#7)

### Documentation

- README "Quick start" rewritten to use the `yabase/facade`
  module so the headline example no longer trips the project's own
  `assert_ok_pattern = "error"` glinter rule on the encode side.
  A short note explains the encode/decode asymmetry and points
  readers at the unified API for the runtime-encoding-selection
  case. (#6)

## [0.2.1] - 2026-04-07

### Changed

- Replace all custom `list_reverse` implementations with `list.reverse` from stdlib (14 modules)
- `bignum.encode_int` now uses list accumulator instead of O(n^2) string concatenation
- `bignum.count_leading_char` renamed to `count_leading_zeros_str` and uses `char_value` for zero alias handling (e.g. Crockford O->0)
- Shared `find_index` extracted into `bignum` module; Base58 Bitcoin/Flickr deduplicated
- `z85.list_to_string` uses `string.join` instead of recursive concatenation
- `crockford.string_char_at` and `nopadding.find_char_pos` use `let assert` for unreachable branches
- `verify-readme.sh` uses `trap` cleanup and indentation-safe grep patterns
- Example comments clarified to note they do not produce real Bitcoin addresses

### Fixed

- Base91 EOF decode now flushes one final byte (matching C reference implementation)
- `urlsafe_nopadding.decode` now reports the earliest invalid character, not just `=`
- Crockford case-insensitive test was a tautology (compared same input to itself)
- README `8-to-5 bit` compound modifier hyphenation corrected to `8-to-5-bit`

### Added

- `base58check` middle-position `InvalidCharacter` test

## [0.2.0] - 2026-04-07

### Added

- Base2 (binary string), Base8 (octal), Base10 (decimal) encodings
- Base58 Flickr variant with multibase `Z` prefix
- Crockford Base32 check symbol support via `CrockfordCheck` variant and `encode_check` / `decode_check`
- Multibase prefixes `0` (base2), `7` (base8), `9` (base10), `Z` (base58flickr)
- Ascii85 btoa `y` abbreviation for 4 consecutive spaces (0x20202020)
- Adobe Ascii85 form-feed whitespace handling (PostScript compliance)
- NoPadding Base64 decoders now reject `=` with `InvalidCharacter`
- Shared `internal/bignum` module for radix-based encodings
- NIST test vectors for SHA-256 (448-bit, 896-bit, padding boundary cases)
- Base91 fixed vectors, error cases, and 48/64-byte roundtrip tests
- CI: README code snippet compilation check, examples compile check, OTP 26/27/28 matrix
- Multibase coverage matrix in README
- Examples for JWT, QR, Bitcoin, and multibase use cases
- Leading-zero preservation documented for big-integer encodings

### Changed

- **BREAKING**: `Base58` is now `Base58(Bitcoin)` in the `Encoding` ADT
- **BREAKING**: `Ascii85`, `AdobeAscii85`, `Rfc1924Base85`, `Z85` are now `Base85(Btoa)`, `Base85(Adobe)`, `Base85(Rfc1924)`, `Base85(Z85)`
- **BREAKING**: `yabase.decode_as` renamed to `yabase.decode`
- **BREAKING**: `yabase.encode_with_prefix` / `yabase.decode` (multibase) renamed to `yabase.encode_multibase` / `yabase.decode_multibase`
- **BREAKING**: `bech32.encode(hrp, data)` / `bech32.encode_m(hrp, data)` merged into `bech32.encode(variant, hrp, data)`
- **BREAKING**: `CrockfordCheck` added to `Base32Variant` for unified API access
- Crockford Base32 now uses number encoding per spec (was byte-stream chunking)
- Bech32 module documentation clarified as byte-payload convenience API
- `yabase/core/dispatcher` marked as internal module
- All encoder functions refactored from O(n^2) string concat to O(n) list accumulator

### Fixed

- SHA-256 now uses full 64-bit length in padding (was 32-bit)
- Crockford Base32 encoding now matches the published specification
- Base91 data corruption on inputs longer than ~30 bytes (bigint bit-buffer overflow)
- Adobe Ascii85 now accepts form-feed as whitespace per PostScript spec

## [0.1.0] - 2026-04-06

### Added

- Unified, type-safe `Encoding` type covering 19 binary-to-text encodings
- Three API layers: low-level modules, unified dispatch (`yabase.encode` / `yabase.decode_as`), and facade shortcuts
- Multibase prefix encoding and auto-detection (`yabase.encode_with_prefix` / `yabase.decode`)
- Base16 (hex) encoding and decoding
- Base32 variants: RFC4648, Hex, Crockford, Clockwork, z-base-32
- Base64 variants: Standard, URL-safe, NoPadding, DQ (Dragon Quest hiragana)
- Base36, Base45 (RFC 9285), Base58 (Bitcoin), Base62
- Base91, Ascii85, Adobe Ascii85 (PDF/PostScript), Z85, RFC 1924 Base85
- Base58Check (version byte + SHA-256 double-hash checksum, BIP reference)
- Bech32 (BIP 173) and Bech32m (BIP 350) with separate API (HRP + checksum)
- Pure Gleam SHA-256 implementation for Base58Check checksum computation
- `CodecError` type with specific error variants: `InvalidCharacter`, `InvalidLength`, `Overflow`, `UnsupportedPrefix`, `UnsupportedMultibaseEncoding`, `InvalidChecksum`, `InvalidHrp`
- `Decoded` type for multibase auto-detection results
- `Bech32Decoded` type with HRP, data, and variant auto-detection
- `Base58CheckDecoded` type with version byte and payload
- Input validation: padding position checks (Base32/Base64), trailing data rejection, pure-padding rejection, length constraints (Z85). Note: non-canonical trailing bits in Base32/Base64 padding are accepted per RFC 4648 decoder flexibility; canonicality is not enforced
- 302 tests covering fixed vectors, roundtrips, error cases, and edge cases
