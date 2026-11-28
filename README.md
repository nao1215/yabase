# yabase

[![CI](https://github.com/nao1215/yabase/actions/workflows/ci.yml/badge.svg)](https://github.com/nao1215/yabase/actions/workflows/ci.yml)
![Coverage](https://raw.githubusercontent.com/nao1215/octocovs-central-repo/main/badges/nao1215/yabase/coverage.svg)
[![Gitleaks](https://github.com/nao1215/yabase/actions/workflows/gitleaks.yml/badge.svg)](https://github.com/nao1215/yabase/actions/workflows/gitleaks.yml)
[![Trivy](https://github.com/nao1215/yabase/actions/workflows/trivy.yml/badge.svg)](https://github.com/nao1215/yabase/actions/workflows/trivy.yml)
[![OSV-Scanner](https://github.com/nao1215/yabase/actions/workflows/osv-scan.yml/badge.svg)](https://github.com/nao1215/yabase/actions/workflows/osv-scan.yml)
[![Hex](https://img.shields.io/hexpm/v/yabase)](https://hex.pm/packages/yabase)
[![Hex Docs](https://img.shields.io/badge/hex-docs-ffaff3)](https://hexdocs.pm/yabase/)
[![Hex Downloads](https://img.shields.io/hexpm/dt/yabase)](https://hex.pm/packages/yabase)
[![License](https://img.shields.io/github/license/nao1215/yabase)](https://github.com/nao1215/yabase/blob/main/LICENSE)
[![OpenSSF Scorecard](https://api.scorecard.dev/projects/github.com/nao1215/yabase/badge)](https://scorecard.dev/viewer/?uri=github.com/nao1215/yabase)

![yabase_logo](https://raw.githubusercontent.com/nao1215/yabase/main/doc/img/yabase_logo_small.png)

yabase converts bytes to text and back in Gleam.

Gleam's [standard library](https://hexdocs.pm/gleam_stdlib/gleam/bit_array.html) provides hexadecimal and Base64 conversions. yabase adds Base32, Base58Check, Bech32, Base85, and other [encodings](https://hexdocs.pm/yabase/yabase.html#Encoding) through one `Encoding` value. It also decodes multibase input by its prefix and reports where invalid characters occur. All codecs run on Erlang and JavaScript.

## Install

```sh
gleam add yabase
```

Requires Gleam 1.15 or later, with Erlang/OTP 26+ or Node.js 18+. The runtime dependency is `gleam_stdlib`.

## Quick start

Choose an encoding and handle the result. Both operations return `Result`.

```gleam
import yabase

pub fn main() {
  let assert Ok(encoded) = yabase.encode(<<"Hello":utf8>>, using: yabase.Base64)
  let assert True = encoded == "SGVsbG8="
  let assert True = yabase.decode(encoded, using: yabase.Base64) == Ok(<<"Hello":utf8>>)
  let assert True = yabase.decode("A!==", using: yabase.Base64)
    == Error(yabase.InvalidCharacter("!", 1))
}
```

The assertions make this example executable. Application code can use `case` or `result.try` to handle `CodecError`.

## Encodings

The [API reference](https://hexdocs.pm/yabase/yabase.html) lists every `Encoding` variant and operation. Supported families include Base2, Base8, Base10, hexadecimal, Base32, Base36, Base45, Base58, Base62, Base64, Base85 and Base91, plus Base58Check and Bech32/Bech32m checksums.

`Base58Check(version)` and `Bech32Encoding(hrp, variant)` check expected metadata while decoding. `decode_base58check` and `decode_bech32` return records containing the metadata read from the input.

```gleam
import yabase

pub fn main() {
  let assert True = yabase.decode_base58check("26k9aD1PF")
    == Ok(yabase.Base58CheckDecoded(128, <<1>>))
  let assert True = yabase.decode("26k9aD1PF", using: yabase.Base58Check(0))
    == Error(yabase.UnexpectedVersion(0, 128))
}
```

Encoders require whole bytes. A partial byte returns `UnalignedInput`; Z85 and RFC1924 Base85 additionally require groups of four bytes. Metadata and checksum errors have separate variants. `InvalidCharacter` carries the original grapheme and its zero-based position in the complete input.

`decode_base16_strict`, `decode_base32_strict` and `decode_base64_strict` reject spelling or padding that differs from the corresponding encoder's output. The ordinary decoders retain each format's accepted alternatives. See [CodecError](https://hexdocs.pm/yabase/yabase.html#CodecError) for error meanings. Each operation documents its validation order.

## Integer IDs

`encode_int` and `decode_int` support decimal, hexadecimal, RFC4648 Base32, Crockford Base32 with or without its check symbol, Base36, Bitcoin/Flickr Base58, Base58Check and Base62. Decoding requires a canonical representation, with both compact and byte-aligned uppercase hexadecimal accepted.

```gleam
import gleam/option.{Some}
import yabase

pub fn main() {
  let assert True = yabase.encode_int_base16_compact(2025) == Ok("7E9")
  let assert True = yabase.decode_int("7E9", using: yabase.Base16, up_to: Some(2025))
    == Ok(2025)
  let assert True = yabase.decode_int("7E9", using: yabase.Base16, up_to: Some(2024))
    == Error(yabase.Overflow)
}
```

The optional upper bound is inclusive. JavaScript integers are limited to `int53_max` (2^53 − 1); Erlang supports arbitrary precision. This limit applies to integer operations, while byte encodings support larger payloads. `decode_int_base58check` accepts a valid version byte without requiring a particular version.

## Multibase

`encode_multibase` adds the format prefix. `decode_multibase` detects it and returns `Decoded(encoding, data)`. The table lists every accepted prefix; entries marked “decode only” use another prefix when encoding.

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

The table is generated from the public registry with `just gen-readme`; CI checks that all 23 accepted prefixes remain represented.

## Examples and development

[Runnable examples](https://github.com/nao1215/yabase/tree/main/examples) cover URL-safe Base64, Base45, Bitcoin checksums and multibase detection. See [CONTRIBUTING.md](https://github.com/nao1215/yabase/blob/main/CONTRIBUTING.md) for development commands and [doc/testing.md](https://github.com/nao1215/yabase/blob/main/doc/testing.md) for test coverage and independent encoding oracles.

## Verifying releases

Each GitHub Release attaches the tarball published to Hex (`yabase-<version>.tar`), `checksums.txt`, a cosign signature bundle (`checksums.txt.sigstore.json`) and build provenance (`yabase-<version>.intoto.jsonl`). The release workflow downloads the tarball from Hex after `gleam publish` and checks it against the checksum Hex records before signing it, so the tarball you get from Hex is the one that is signed and attested.

```sh
curl -fsSLO https://repo.hex.pm/tarballs/yabase-<version>.tar
gh attestation verify yabase-<version>.tar --repo nao1215/yabase
```

To check the signature as well, download `checksums.txt` and `checksums.txt.sigstore.json` from the Release into the same directory. The workflow runs on the release tag, or on `main` when the assets of a published tag are attached again.

```sh
cosign verify-blob \
  --bundle checksums.txt.sigstore.json \
  --certificate-identity-regexp '^https://github\.com/nao1215/yabase/\.github/workflows/release\.yml@refs/(tags/v.+|heads/main)$' \
  --certificate-oidc-issuer https://token.actions.githubusercontent.com \
  checksums.txt
sha256sum --check checksums.txt
```

## License

[MIT](https://github.com/nao1215/yabase/blob/main/LICENSE)
