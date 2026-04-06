# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/),
and this project adheres to [Semantic Versioning](https://semver.org/).

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
- Strict input validation: padding position checks (Base32/Base64), trailing data rejection, pure-padding rejection, length constraints (Z85)
- 302 tests covering fixed vectors, roundtrips, error cases, and edge cases
