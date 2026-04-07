# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/),
and this project adheres to [Semantic Versioning](https://semver.org/).

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
