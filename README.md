# yabase

[![CI](https://github.com/nao1215/yabase/actions/workflows/ci.yml/badge.svg)](https://github.com/nao1215/yabase/actions/workflows/ci.yml)
[![Gitleaks](https://github.com/nao1215/yabase/actions/workflows/gitleaks.yml/badge.svg)](https://github.com/nao1215/yabase/actions/workflows/gitleaks.yml)
[![Trivy](https://github.com/nao1215/yabase/actions/workflows/trivy.yml/badge.svg)](https://github.com/nao1215/yabase/actions/workflows/trivy.yml)
[![OSV-Scanner](https://github.com/nao1215/yabase/actions/workflows/osv-scan.yml/badge.svg)](https://github.com/nao1215/yabase/actions/workflows/osv-scan.yml)
[![Hex](https://img.shields.io/hexpm/v/yabase)](https://hex.pm/packages/yabase)
[![Hex Docs](https://img.shields.io/badge/hex-docs-ffaff3)](https://hexdocs.pm/yabase/)
[![Hex Downloads](https://img.shields.io/hexpm/dt/yabase)](https://hex.pm/packages/yabase)
[![License](https://img.shields.io/github/license/nao1215/yabase)](./LICENSE)
[![OpenSSF Scorecard](https://api.scorecard.dev/projects/github.com/nao1215/yabase/badge)](https://scorecard.dev/viewer/?uri=github.com/nao1215/yabase)

![yabase_logo](https://raw.githubusercontent.com/nao1215/yabase/main/doc/img/yabase_logo_small.png)

Yet Another Base: binary-to-text encodings for Gleam behind one typed interface. Each encoding is a value you can pass around, multibase prefixes are detected on decode, and the package is pure Gleam with no external dependencies.

## Install

```sh
gleam add yabase
```

## Quick start

`yabase/facade` has one function per encoding. `encode_*` returns a
`String`, since these encodings cannot fail on a byte-aligned `BitArray`.
`decode_*` returns a `Result`.

```gleam
import yabase/facade

pub fn main() {
  let encoded = facade.encode_base64(<<"Hello":utf8>>)
  // encoded == "SGVsbG8="

  let assert Ok(_decoded) = facade.decode_base64(encoded)
  // _decoded == <<"Hello":utf8>>
}
```

The README uses `let assert` to keep snippets short. In application code, propagate the decode error instead.

## Requirements

- Gleam 1.15 or later
- Erlang/OTP 26 or later (CI tests OTP 26, 27 and 28 on Gleam 1.15.0, and OTP 29 on the latest Gleam 1.x)
- Node.js 18 or later (when targeting JavaScript)

## Supported targets

All encodings give the same output on Erlang and JavaScript, for inputs of
any size. The JavaScript target needs no FFI.

CI runs `gleam test --target javascript` on Node 18 (the supported minimum;
a failure blocks release) and on Node LTS (`lts/*`). The
release workflow runs the same matrix before `gleam publish`.

## Strictness

`decode_base32`, `decode_base64`, and their URL-safe and no-padding
variants accept non-canonical pad bits, as the spec allows. The `_strict`
versions reject them with a typed error per RFC 4648 §3.5. Use them for
input you do not control, such as auth tokens or signed payloads.

```gleam
import yabase/facade

// Lenient default — accepts non-canonical trailing pad bits:
let _lenient = facade.decode_base64("TR==")
// -> Ok(<<...>>)

// Strict — rejects non-canonical input per RFC 4648 §3.5:
let _strict = facade.decode_base64_strict("TR==")
// -> Error(NonCanonical)
```

Strict decoders are available as `yabase/base16.decode_strict`,
`yabase/base32/rfc4648.decode_strict` and `yabase/base64/standard.decode_strict`.
The facade exposes `decode_base32_strict` and `decode_base64_strict`.
The URL-safe, no-padding and Base32 Hex modules have no strict decoder.

## Integer IDs

`yabase/intid` turns an `Int`, such as a database id, into a short URL-safe string and back.

```gleam
import yabase/intid

pub fn main() {
  let assert Ok(token) = intid.encode_int_base58(42)
  // token == "j"

  let assert Ok(_n) = intid.decode_int_base58(token)
  // _n == 42
}
```

Available: `encode_int_base32_rfc4648`, `encode_int_base32_crockford`, `encode_int_base36`, `encode_int_base58`, `encode_int_base58_flickr`, `encode_int_base62` and their matching `decode_int_*`. All `encode_int_*` functions return `Result(String, CodecError)` and all `decode_int_*` functions return `Result(Int, CodecError)`.

`decode_int_*` accepts canonical text and rejects extra leading zeros, alternate letter case and Crockford aliases with `Error(NonCanonical)`. Base16 accepts both its byte-aligned and compact encoder outputs; Base58Check requires a minimal non-empty payload. `encode_int_*` rejects negative numbers with `Error(NegativeValue(value))`; map them to something like zigzag first.

On Erlang, `decode_int_*` can return an `Int` of any size. On JavaScript, integer encoders and decoders return `Error(Overflow)` above `Number.MAX_SAFE_INTEGER`. Before storing an ID in a fixed-width column, use `decode_int_*_bounded(input:, max:)`. `intid.int64_max` is `2^63 - 1` on Erlang and `2^53 - 1` on JavaScript; `intid.int53_max` is `2^53 - 1` on both.

```gleam
import yabase/intid

pub fn lookup(public_id: String) -> Bool {
  case intid.decode_int_base58_bounded(input: public_id, max: intid.int64_max) {
    // Bind `_internal_id` to `sqlight.int(_)` etc.; the value fits BIGINT.
    Ok(_internal_id) -> True
    // Respond 404/400; input was malformed or numerically out of range.
    Error(_) -> False
  }
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

### Checksum-bearing

The version byte or HRP is part of the `Encoding` value:

| Encoding | Module | `Encoding` constructor | Description |
|----------|--------|-----------------------|-------------|
| Base58Check | `yabase/base58check` | `encoding.base58_check(version)` | Bitcoin-style: version byte + payload + SHA-256 double-hash checksum |
| Bech32 | `yabase/bech32` | `encoding.bech32(hrp)` | BIP 173: byte-payload encoding (HRP + 8-to-5 conversion + checksum), not SegWit address validation |
| Bech32m | `yabase/bech32` | `encoding.bech32m(hrp)` | BIP 350: improved checksum constant, same byte-payload API |

They work with `yabase.encode` / `yabase.decode`:

```gleam
import yabase
import yabase/core/encoding

let assert Ok(_encoded) =
  yabase.encode(encoding.bech32("bc"), <<0xDE, 0xAD, 0xBE, 0xEF>>)
```

`yabase.decode` rejects input whose Base58Check version or Bech32 HRP and
variant differ from the `Encoding` value. To read that metadata from the
input instead, use `yabase/base58check.decode` or `yabase/bech32.decode`.

## API layers

Start with `yabase/facade` (shown in the quick start). Use `yabase` with an
`Encoding` value when the encoding is chosen at runtime, and the low-level
modules such as `yabase/base64/standard` for one specific codec.

### 1. Low-level modules (direct usage)

```gleam
import yabase/base64/standard
import yabase/base32/clockwork

let _encoded = standard.encode(<<"Hello":utf8>>)
// "SGVsbG8="

let assert Ok(_data) = clockwork.decode("91JPRV3F41BPYWKCCGGG")
```

### 2. Unified API (dispatch by Encoding type)

```gleam
import yabase
import yabase/core/encoding

let assert Ok(encoded) =
  yabase.encode(encoding.base32_clockwork(), <<"Hello":utf8>>)
let assert Ok(_decoded) =
  yabase.decode(encoding.base32_clockwork(), encoded)
```

## Return types of `encode`

Most per-module `encode` functions return `String`; four return `Result`:

| Codec | `encode` signature |
| --- | --- |
| `base2`, `base8`, `base10`, `base16`, `base32/{rfc4648, hex, crockford, clockwork, zbase32}`, `base36`, `base45`, `base62`, `base64/{standard, urlsafe, nopadding, urlsafe_nopadding, dq}`, `base91`, `base58/{bitcoin, flickr}`, `ascii85`, `adobe_ascii85` | `fn(BitArray) -> String` |
| `z85`, `rfc1924_base85` | `fn(BitArray) -> Result(String, CodecError)` |
| `base58check` | `fn(Int, BitArray) -> Result(String, CodecError)` |
| `bech32` | `fn(String, BitArray, Bech32Variant) -> Result(String, CodecError)` |

`z85` and `rfc1924_base85` need a length that is a multiple of 4 bytes,
`base58check` needs a version in `0..=255`, and `bech32` validates the HRP
and variant. These four return an error for input that is not a whole
number of bytes; every other codec panics on it through
`yabase/core/guard.assert_byte_aligned` (see #64).

For one `Result(String, CodecError)` shape across all codecs, for example
in [`metamon`](https://github.com/nao1215/metamon)'s `forall_round_trip`,
use `yabase.encode`.

### Multibase support

```gleam
import yabase
import yabase/core/encoding

// Encode with multibase prefix
let assert Ok(prefixed) =
  yabase.encode_multibase(encoding.base16(), <<"Hello":utf8>>)
// "f48656c6c6f"

// Decode with auto-detection. The result is an opaque `Decoded` value
// — use `encoding.decoded_encoding/1` and `encoding.decoded_data/1`
// to inspect it, and `encoding.multibase_name/1` if you need to
// label the detected codec.
let assert Ok(d) = yabase.decode_multibase(prefixed)
let assert True = encoding.decoded_encoding(d) == encoding.base16()
let _data = encoding.decoded_data(d)
```

### Selecting codecs by target

`encoding.supports_target` now returns `True` for every encoding on both
targets; code that branches on it keeps working.

```gleam
import yabase/core/encoding.{type Decoded}
import yabase/core/multibase

pub fn safe_decode_for_javascript(
  prefixed: String,
) -> Result(Decoded, Nil) {
  let js = encoding.target_javascript()
  case multibase.decode(prefixed) {
    Ok(decoded) -> {
      let enc = encoding.decoded_encoding(decoded)
      case encoding.supports_target(enc, js) {
        True -> Ok(decoded)
        False -> Error(Nil)
      }
    }
    Error(_) -> Error(Nil)
  }
}
```

`encoding.supports_target(_, encoding.target_erlang())` is always `True`.
`encoding.is_javascript_safe/1` is the same check without a `Target` value.
For `intid`, decode with `intid.decode_int_*_bounded(..., max: intid.int53_max)`
when the value goes to a JavaScript `number`.

### Multibase prefix coverage

[Multibase](https://github.com/multiformats/multibase) prefixes. "decode only" prefixes are accepted by `decode_multibase`, while `encode_multibase` emits the prefix in parentheses.

The table comes from `yabase/core/encoding`; regenerate it with `just gen-readme`. CI fails if it differs from `multibase_prefix`, `from_multibase_prefix`, and `multibase_name`.

<!-- BEGIN: multibase-prefix-table -->

| Prefix | Encoding | Support |
|--------|----------|---------|
| `0` | base2 | encode + decode |
| `7` | base8 | encode + decode |
| `9` | base10 | encode + decode |
| `f` | base16 | encode + decode |
| `F` | base16 | decode only (encode emits `f`) |
| `c` | base32pad | encode + decode |
| `C` | base32pad | decode only (encode emits `c`) |
| `b` | base32pad | decode only (encode emits `c`) |
| `B` | base32pad | decode only (encode emits `c`) |
| `t` | base32hexpad | encode + decode |
| `T` | base32hexpad | decode only (encode emits `t`) |
| `v` | base32hexpad | decode only (encode emits `t`) |
| `V` | base32hexpad | decode only (encode emits `t`) |
| `k` | base36 | encode + decode |
| `K` | base36 | decode only (encode emits `k`) |
| `R` | base45 | encode + decode |
| `z` | base58btc | encode + decode |
| `Z` | base58flickr | encode + decode |
| `h` | base32z | encode + decode |
| `M` | base64pad | encode + decode |
| `m` | base64 | encode + decode |
| `U` | base64urlpad | encode + decode |
| `u` | base64url | encode + decode |

<!-- END: multibase-prefix-table -->

The `c` and `t` decoder lanes also accept unpadded input (`b` / `B`, `v` / `V`); they share the same underlying decoder.

### Bech32 / Bech32m (BIP 173, BIP 350)

Takes raw bytes and does the 8-to-5-bit conversion and checksum. It does not validate SegWit addresses (witness version, program length).

```gleam
import yabase/bech32
import yabase/core/error.{Bech32}

// Bech32 encode
let assert Ok(encoded) = bech32.encode(Bech32, "bc", <<0, 14, 20, 15>>)
// "bc1..." with 6-char checksum

// Auto-detect Bech32 vs Bech32m on decode
let assert Ok(_decoded) = bech32.decode(encoded)
// _decoded.hrp == "bc", _decoded.variant == Bech32
```

### Base58Check (Bitcoin)

```gleam
import yabase/base58check

// Encode with version byte 0 (Bitcoin mainnet P2PKH)
let assert Ok(encoded) = base58check.encode(0, <<0xab, 0xcd>>)
// Base58 string with 4-byte SHA-256 checksum

// Decode and verify checksum
let assert Ok(_decoded) = base58check.decode(encoded)
// _decoded.version == 0, _decoded.payload == <<0xab, 0xcd>>
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
| `yabase/intid` | `Int <-> short string` helpers for IDs (Base32 / Base36 / Base58 / Base62) |
| `yabase/base91` | Base91 |
| `yabase/ascii85` | Ascii85 (btoa) |
| `yabase/adobe_ascii85` | Adobe Ascii85 (PDF/PostScript, `<~` `~>` delimiters) |
| `yabase/rfc1924_base85` | RFC 1924 Base85 |
| `yabase/z85` | Z85 (ZeroMQ) |
| `yabase/base58check` | Base58Check (version byte + SHA-256 checksum) |
| `yabase/bech32` | Bech32/Bech32m byte-payload encoding with checksum (not SegWit address validation) |

## Error handling

Functions that can fail return `Result(_, CodecError)`:

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

`CodecError` variants:

| Variant | Returned from | Meaning |
|---------|---------------|---------|
| `InvalidCharacter(character, position)` | decode | Input contains a character not in the alphabet |
| `InvalidLength(length)` | encode / decode | Input length is not valid for the encoding |
| `Overflow` | encode / decode | Decoded value overflows the expected range (Base45, Ascii85, Adobe Ascii85, Z85, RFC 1924 Base85); `base58check.encode` returns this when version is outside 0..255 |
| `UnsupportedPrefix(prefix)` | `yabase.decode_multibase` | Unknown multibase prefix during auto-detection |
| `UnsupportedMultibaseEncoding(name)` | `yabase.encode_multibase` | Encoding has no assigned multibase prefix (e.g. Base64 DQ) |
| `InvalidChecksum` | `base58check.decode`, `bech32.decode` | Checksum verification failed |
| `InvalidHrp(reason)` | `bech32.encode`, `bech32.decode` | Invalid human-readable part in Bech32 |

## Examples

Runnable programs in [`examples/`](examples/):

| File | Use case |
|------|----------|
| `jwt_urlsafe_base64.gleam` | JWT header/payload encoding (URL-safe Base64 without padding) |
| `qr_base45.gleam` | QR-code-friendly encoding (RFC 9285) |
| `bitcoin_base58check.gleam` | Bitcoin address encoding with version byte and checksum |
| `bitcoin_bech32.gleam` | Bech32/Bech32m address framing (BIP 173 / BIP 350) |
| `multibase_auto_detect.gleam` | Prefix-based encoding auto-detection for content-addressed systems |

## Development

[mise](https://mise.jdx.dev/) installs Gleam and Erlang, and [just](https://just.systems/) runs the tasks.

```sh
mise install    # install Gleam and Erlang
just ci         # download deps and run all checks, including glinter
just lint       # run glinter with the repo config
just test       # gleam test
just format     # gleam format
just check      # all checks without deps download
```

## Contributing

See [CONTRIBUTING.md](https://github.com/nao1215/yabase/blob/main/CONTRIBUTING.md) for details.

## Testing

| Technique | Bug class caught here |
|---|---|
| Examples and unit tests | [Wrong output against published test vectors, accepted invalid input](doc/testing.md#examples-and-unit-tests) |
| Generated properties | [Encodings that do not round-trip](doc/testing.md#generated-properties) |
| Differential testing | [Base64, Base16 and SHA-256 that disagree with independent implementations](doc/testing.md#differential-testing) |
| Mutation testing | [Assertions that miss a changed operator or branch](doc/testing.md#mutation-testing) |

## Verifying releases

Each GitHub Release attaches the Hex package tarball (`yabase-<version>.tar`),
`checksums.txt`, a cosign signature bundle (`checksums.txt.sigstore.json`) and
build provenance (`yabase-<version>.intoto.jsonl`). Download the assets, then:

```sh
gh attestation verify yabase-<version>.tar --repo nao1215/yabase

cosign verify-blob \
  --bundle checksums.txt.sigstore.json \
  --certificate-identity-regexp '^https://github\.com/nao1215/yabase/\.github/workflows/release\.yml@refs/tags/v' \
  --certificate-oidc-issuer https://token.actions.githubusercontent.com \
  checksums.txt
sha256sum --check checksums.txt
```

## License

[MIT](https://github.com/nao1215/yabase/blob/main/LICENSE)
