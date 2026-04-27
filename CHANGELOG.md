# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/),
and this project adheres to [Semantic Versioning](https://semver.org/).

## [Unreleased]

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
