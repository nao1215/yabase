# yabase

[![CI](https://github.com/nao1215/yabase/actions/workflows/ci.yml/badge.svg)](https://github.com/nao1215/yabase/actions/workflows/ci.yml)
[![Hex.pm](https://img.shields.io/hexpm/v/yabase)](https://hex.pm/packages/yabase)

![yabase_logo](https://raw.githubusercontent.com/nao1215/yabase/main/doc/img/yabase_logo_small.png)

Yet Another Base -- a unified, type-safe interface for multiple binary-to-text encodings in Gleam.

- Encoding schemes are first-class values.
- Both low-level (direct module) and high-level (unified dispatch) APIs.
- Multibase prefix support for auto-detection.
- Pure Gleam implementation, no external dependencies.

## Requirements

- Gleam 1.15 or later
- Erlang/OTP 26 or later (CI tests OTP 26, 27, 28)

## Install

```sh
gleam add yabase
```

## Quick start

```gleam
import yabase
import yabase/core/encoding.{Base64, Standard}

pub fn main() {
  // Unified API
  let assert Ok(encoded) = yabase.encode(Base64(Standard), <<"Hello":utf8>>)
  // encoded == "SGVsbG8="

  let assert Ok(decoded) = yabase.decode(Base64(Standard), encoded)
  // decoded == <<"Hello":utf8>>
}
```

## Supported encodings

### Core

| Encoding | Variants |
|----------|----------|
| Base2 | (binary string) |
| Base8 | (octal) |
| Base10 | (decimal) |
| Base16 | (hex) |
| Base32 | RFC4648, Hex, Crockford (with optional check symbol), Clockwork, z-base-32 |
| Base64 | Standard, URL-safe, No padding, URL-safe no padding, DQ (hiragana) |
| Base58 | Bitcoin, Flickr |

### Additional

| Encoding | Description |
|----------|-------------|
| Base36 | 0-9, a-z (case-insensitive decode) |
| Base45 | RFC 9285 (QR-code friendly) |
| Base62 | 0-9, A-Z, a-z |
| Base91 | 91 printable ASCII characters |
| Ascii85 | btoa style |
| Adobe Ascii85 | PDF/PostScript with `<~` `~>` delimiters |
| Z85 | ZeroMQ variant of Ascii85 |
| RFC 1924 Base85 | RFC 1924 alphabet |

Big-integer encodings (Base8, Base10, Base36, Base58, Base62, Crockford Base32) preserve leading zero bytes: each leading 0x00 byte encodes as the alphabet's zero character, and decoding reverses this. For example, `base10.decode("001")` returns `Ok(<<0, 0, 1>>)`.

### Checksum-bearing (separate API)

These encodings carry metadata (version bytes, checksums, HRP) and have their own API outside the `Encoding` ADT.

| Encoding | Module | Description |
|----------|--------|-------------|
| Base58Check | `yabase/base58check` | Bitcoin-style: version byte + payload + SHA-256 double-hash checksum |
| Bech32 | `yabase/bech32` | BIP 173: byte-payload encoding (HRP + 8-to-5 conversion + checksum), not SegWit address validation |
| Bech32m | `yabase/bech32` | BIP 350: improved checksum constant, same byte-payload API |

## API layers

yabase provides three API layers:

- **Start with `yabase/facade`** -- one function per encoding, no type parameters. Covers most use cases.
- **Use the unified API (`yabase`)** when you need to select an encoding at runtime (e.g. user config, multibase auto-detection).
- **Use low-level modules** (`yabase/base64/standard`, etc.) when you need full control over a specific codec.

### 1. Low-level modules (direct usage)

Each encoding is accessible directly:

```gleam
import yabase/base64/standard
import yabase/base32/clockwork
import yabase/base45

let encoded = standard.encode(<<"Hello":utf8>>)
// "SGVsbG8="

let assert Ok(data) = clockwork.decode("91JPRV3F41BPYWKCCGGG")
```

### 2. Unified API (dispatch by Encoding type)

```gleam
import yabase
import yabase/core/encoding.{Base32, Clockwork}

let assert Ok(encoded) = yabase.encode(Base32(Clockwork), <<"Hello":utf8>>)
let assert Ok(decoded) = yabase.decode(Base32(Clockwork), encoded)
```

### 3. Facade (developer-friendly shortcuts)

```gleam
import yabase/facade

let encoded = facade.encode_base64(<<"Hello":utf8>>)
let assert Ok(decoded) = facade.decode_base64(encoded)
```

### Multibase support

Prefix-based encoding and auto-detection:

```gleam
import yabase
import yabase/core/encoding.{Base16, Base58, Bitcoin, Decoded}

// Encode with multibase prefix
let assert Ok(prefixed) = yabase.encode_multibase(Base16, <<"Hello":utf8>>)
// "f48656c6c6f"

// Decode with auto-detection
let assert Ok(Decoded(encoding: Base16, data: data)) =
  yabase.decode_multibase(prefixed)
```

### Multibase prefix coverage

yabase supports the following [multibase](https://github.com/multiformats/multibase) prefixes.
"encode + decode" means `encode_multibase` emits this prefix and `decode_multibase` recognizes it.
"decode only" means `decode_multibase` recognizes the prefix but `encode_multibase` uses the canonical form.

| Prefix | Encoding | Support |
|--------|----------|---------|
| `0` | base2 | encode + decode |
| `7` | base8 | encode + decode |
| `9` | base10 | encode + decode |
| `f` | base16 (lowercase) | encode + decode |
| `F` | base16 (uppercase) | decode only (encode emits `f`) |
| `b` / `B` | base32 (no padding) | decode only (encode emits `c`) |
| `c` / `C` | base32pad | encode + decode |
| `t` / `T` | base32hexpad | encode + decode |
| `v` / `V` | base32hex (no padding) | decode only (encode emits `t`) |
| `h` | base32z | encode + decode |
| `k` / `K` | base36 | encode + decode |
| `R` | base45 | encode + decode |
| `z` | base58btc | encode + decode |
| `Z` | base58flickr | encode + decode |
| `m` | base64 (no padding) | encode + decode |
| `M` | base64pad | encode + decode |
| `u` | base64url (no padding) | encode + decode |
| `U` | base64urlpad | encode + decode |

### Bech32 / Bech32m (BIP 173, BIP 350)

Byte-payload convenience API. Takes raw bytes, handles 8-to-5 bit conversion internally, and produces the checksummed Bech32 string. Does not validate SegWit address semantics (witness version, program length):

```gleam
import yabase/bech32
import yabase/core/encoding.{Bech32, Bech32m}

// Bech32 encode
let assert Ok(encoded) = bech32.encode(Bech32, "bc", <<0, 14, 20, 15>>)
// "bc1..." with 6-char checksum

// Auto-detect Bech32 vs Bech32m on decode
let assert Ok(decoded) = bech32.decode(encoded)
// decoded.hrp == "bc", decoded.variant == Bech32
```

### Base58Check (Bitcoin)

```gleam
import yabase/base58check

// Encode with version byte 0 (Bitcoin mainnet P2PKH)
let assert Ok(encoded) = base58check.encode(0, <<0xab, 0xcd>>)
// Base58 string with 4-byte SHA-256 checksum

// Decode and verify checksum
let assert Ok(decoded) = base58check.decode(encoded)
// decoded.version == 0, decoded.payload == <<0xab, 0xcd>>
```

## Modules

| Module | Responsibility |
|--------|---------------|
| `yabase` | Top-level unified API: `encode`, `decode`, `encode_multibase`, `decode_multibase` |
| `yabase/facade` | Developer-friendly shortcut functions for each encoding |
| `yabase/core/encoding` | Type definitions: `Encoding`, `Decoded`, `CodecError` |
| `yabase/core/multibase` | Multibase prefix encoding and auto-detection |
| `yabase/base2` | Base2 (binary string) |
| `yabase/base8` | Base8 (octal) |
| `yabase/base10` | Base10 (decimal) |
| `yabase/base16` | Base16 (hex) |
| `yabase/base32/*` | Base32 variants: `rfc4648`, `hex`, `crockford` (with `encode_check`/`decode_check`), `clockwork`, `zbase32` |
| `yabase/base64/*` | Base64 variants: `standard`, `urlsafe`, `nopadding`, `urlsafe_nopadding`, `dq` |
| `yabase/base36` | Base36 |
| `yabase/base45` | Base45 (RFC 9285) |
| `yabase/base58/bitcoin` | Base58 (Bitcoin alphabet) |
| `yabase/base58/flickr` | Base58 (Flickr alphabet) |
| `yabase/base62` | Base62 |
| `yabase/base91` | Base91 |
| `yabase/ascii85` | Ascii85 (btoa) |
| `yabase/adobe_ascii85` | Adobe Ascii85 (PDF/PostScript, `<~` `~>` delimiters) |
| `yabase/rfc1924_base85` | RFC 1924 Base85 |
| `yabase/z85` | Z85 (ZeroMQ) |
| `yabase/base58check` | Base58Check (version byte + SHA-256 checksum) |
| `yabase/bech32` | Bech32/Bech32m byte-payload encoding with checksum (not SegWit address validation) |

## Error handling

Encode and decode functions that can fail return `Result(_, CodecError)`. The concrete return types vary by API:

| Function | Return type |
|----------|-------------|
| `yabase.encode` | `Result(String, CodecError)` |
| `yabase.decode` | `Result(BitArray, CodecError)` |
| `yabase.encode_multibase` | `Result(String, CodecError)` |
| `yabase.decode_multibase` | `Result(Decoded, CodecError)` |
| Low-level `*.decode` | `Result(BitArray, CodecError)` |
| Low-level `*.encode` | `String` (total; except `z85`/`rfc1924_base85` which return `Result`) |
| `bech32.encode(variant, hrp, data)` | `Result(String, CodecError)` |
| `bech32.decode` | `Result(Bech32Decoded, CodecError)` |
| `base58check.encode` | `Result(String, CodecError)` |
| `base58check.decode` | `Result(Base58CheckDecoded, CodecError)` |

The `CodecError` type provides specific error information:

| Variant | Returned from | Meaning |
|---------|---------------|---------|
| `InvalidCharacter(character, position)` | decode | Input contains a character not in the alphabet |
| `InvalidLength(length)` | encode / decode | Input length is not valid for the encoding |
| `Overflow` | decode | Decoded value overflows the expected range (Base45, Z85, Adobe Ascii85, RFC 1924 Base85) |
| `UnsupportedPrefix(prefix)` | `yabase.decode_multibase` | Unknown multibase prefix during auto-detection |
| `UnsupportedMultibaseEncoding(name)` | `yabase.encode_multibase` | Encoding has no assigned multibase prefix (e.g. Base64 DQ) |
| `InvalidChecksum` | `base58check.decode`, `bech32.decode` | Checksum verification failed |
| `InvalidHrp(reason)` | `bech32.encode`, `bech32.decode` | Invalid human-readable part in Bech32 |

## Examples

The [`examples/`](examples/) directory contains runnable use-case examples:

| File | Use case |
|------|----------|
| `jwt_urlsafe_base64.gleam` | JWT header/payload encoding (URL-safe Base64 without padding) |
| `qr_base45.gleam` | QR-code-friendly encoding (RFC 9285) |
| `bitcoin_base58check.gleam` | Bitcoin address encoding with version byte and checksum |
| `bitcoin_bech32.gleam` | Bech32/Bech32m address framing (BIP 173 / BIP 350) |
| `multibase_auto_detect.gleam` | Prefix-based encoding auto-detection for content-addressed systems |

## Development

This project uses [mise](https://mise.jdx.dev/) to manage Gleam and Erlang versions, and [just](https://just.systems/) as a task runner.

```sh
mise install    # install Gleam and Erlang
just ci         # format check, typecheck, build, test
just test       # gleam test
just format     # gleam format
just check      # all checks without deps download
```

## Contributing

Contributions are welcome. See [CONTRIBUTING.md](https://github.com/nao1215/yabase/blob/main/CONTRIBUTING.md) for details.

## License

[MIT](https://github.com/nao1215/yabase/blob/main/LICENSE)
