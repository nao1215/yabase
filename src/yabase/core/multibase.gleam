/// Multibase prefix-based encoding and decoding.
///
/// Prefix assignments follow the official multibase registry:
/// https://github.com/multiformats/multibase/blob/master/multibase.csv
///
/// Encodings that have no official multibase code point (Base62,
/// Base91, Base85 Btoa/Adobe/Z85, Crockford, Clockwork, DQ) return
/// `Error(UnsupportedMultibaseEncoding)` from `encode_with_prefix`.
import gleam/result
import gleam/string
import yabase/core/dispatcher
import yabase/core/encoding.{
  type CodecError, type Decoded, type Encoding, Adobe, Base10 as Base10Encoding,
  Base16 as Base16Encoding, Base2 as Base2Encoding, Base32 as Base32Encoding,
  Base36 as Base36Encoding, Base45 as Base45Encoding, Base58 as Base58Encoding,
  Base62 as Base62Encoding, Base64 as Base64Encoding, Base8 as Base8Encoding,
  Base85 as Base85Encoding, Base91 as Base91Encoding, Bitcoin, Btoa, Clockwork,
  Crockford, CrockfordCheck, DQ, Decoded, Flickr, Hex, NoPadding, RFC4648,
  Rfc1924, Standard, UnsupportedMultibaseEncoding, UnsupportedPrefix, UrlSafe,
  UrlSafeNoPadding, Z85, ZBase32,
}

/// Encode data with a multibase prefix.
/// Only encodings with an official multibase code point are supported.
/// Returns `Error(UnsupportedMultibaseEncoding)` otherwise.
pub fn encode_with_prefix(
  enc: Encoding,
  data: BitArray,
) -> Result(String, CodecError) {
  case encoding_to_prefix(enc) {
    Error(Nil) -> Error(UnsupportedMultibaseEncoding(encoding_name(enc)))
    Ok(prefix) ->
      dispatcher.encode(enc, data)
      |> result.map(fn(encoded) { prefix <> encoded })
  }
}

/// Decode a multibase-prefixed string, auto-detecting the encoding.
/// Returns Decoded(encoding, data) where data is the decoded BitArray.
pub fn decode(value: String) -> Result(Decoded, CodecError) {
  case string.pop_grapheme(value) {
    Error(Nil) -> Error(UnsupportedPrefix(""))
    Ok(#(prefix, rest)) ->
      case prefix_to_encoding(prefix) {
        Error(Nil) -> Error(UnsupportedPrefix(prefix))
        Ok(enc) ->
          dispatcher.decode_as(enc, rest)
          |> result.map(fn(data) { Decoded(encoding: enc, data: data) })
      }
  }
}

/// Decode a multibase-prefixed string to raw bytes.
pub fn decode_bytes(value: String) -> Result(BitArray, CodecError) {
  case string.pop_grapheme(value) {
    Error(Nil) -> Error(UnsupportedPrefix(""))
    Ok(#(prefix, rest)) ->
      case prefix_to_encoding(prefix) {
        Error(Nil) -> Error(UnsupportedPrefix(prefix))
        Ok(enc) -> dispatcher.decode_as(enc, rest)
      }
  }
}

/// Map Encoding to its official multibase prefix character.
fn encoding_to_prefix(enc: Encoding) -> Result(String, Nil) {
  case enc {
    Base2Encoding -> Ok("0")
    Base8Encoding -> Ok("7")
    Base10Encoding -> Ok("9")
    Base16Encoding -> Ok("f")
    Base32Encoding(RFC4648) -> Ok("c")
    Base32Encoding(Hex) -> Ok("t")
    Base32Encoding(Crockford) -> Error(Nil)
    Base32Encoding(CrockfordCheck) -> Error(Nil)
    Base32Encoding(Clockwork) -> Error(Nil)
    Base32Encoding(ZBase32) -> Ok("h")
    Base36Encoding -> Ok("k")
    Base45Encoding -> Ok("R")
    Base58Encoding(Bitcoin) -> Ok("z")
    Base58Encoding(Flickr) -> Ok("Z")
    Base62Encoding -> Error(Nil)
    Base64Encoding(Standard) -> Ok("M")
    Base64Encoding(UrlSafe) -> Ok("U")
    Base64Encoding(NoPadding) -> Ok("m")
    Base64Encoding(UrlSafeNoPadding) -> Ok("u")
    Base64Encoding(DQ) -> Error(Nil)
    Base85Encoding(Btoa) -> Error(Nil)
    Base85Encoding(Adobe) -> Error(Nil)
    Base85Encoding(Rfc1924) -> Error(Nil)
    Base85Encoding(Z85) -> Error(Nil)
    Base91Encoding -> Error(Nil)
  }
}

/// Map a multibase prefix character to its Encoding.
fn prefix_to_encoding(prefix: String) -> Result(Encoding, Nil) {
  case prefix {
    "0" -> Ok(Base2Encoding)
    "7" -> Ok(Base8Encoding)
    "9" -> Ok(Base10Encoding)
    "f" | "F" -> Ok(Base16Encoding)
    "c" | "C" -> Ok(Base32Encoding(RFC4648))
    "b" | "B" -> Ok(Base32Encoding(RFC4648))
    "t" | "T" -> Ok(Base32Encoding(Hex))
    "v" | "V" -> Ok(Base32Encoding(Hex))
    "k" | "K" -> Ok(Base36Encoding)
    "R" -> Ok(Base45Encoding)
    "z" -> Ok(Base58Encoding(Bitcoin))
    "Z" -> Ok(Base58Encoding(Flickr))
    "h" -> Ok(Base32Encoding(ZBase32))
    "M" -> Ok(Base64Encoding(Standard))
    "m" -> Ok(Base64Encoding(NoPadding))
    "U" -> Ok(Base64Encoding(UrlSafe))
    "u" -> Ok(Base64Encoding(UrlSafeNoPadding))
    _ -> Error(Nil)
  }
}

fn encoding_name(enc: Encoding) -> String {
  case enc {
    Base2Encoding -> "base2"
    Base8Encoding -> "base8"
    Base10Encoding -> "base10"
    Base16Encoding -> "base16"
    Base32Encoding(RFC4648) -> "base32pad"
    Base32Encoding(Hex) -> "base32hexpad"
    Base32Encoding(Crockford) -> "base32crockford"
    Base32Encoding(CrockfordCheck) -> "base32crockford-check"
    Base32Encoding(Clockwork) -> "base32clockwork"
    Base32Encoding(ZBase32) -> "base32z"
    Base36Encoding -> "base36"
    Base45Encoding -> "base45"
    Base58Encoding(Bitcoin) -> "base58btc"
    Base58Encoding(Flickr) -> "base58flickr"
    Base62Encoding -> "base62"
    Base64Encoding(Standard) -> "base64pad"
    Base64Encoding(UrlSafe) -> "base64urlpad"
    Base64Encoding(NoPadding) -> "base64"
    Base64Encoding(UrlSafeNoPadding) -> "base64url"
    Base64Encoding(DQ) -> "base64dq"
    Base85Encoding(Btoa) -> "ascii85"
    Base85Encoding(Adobe) -> "adobe-ascii85"
    Base85Encoding(Rfc1924) -> "rfc1924-base85"
    Base85Encoding(Z85) -> "z85"
    Base91Encoding -> "base91"
  }
}
