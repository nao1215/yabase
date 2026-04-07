/// Multibase prefix-based encoding and decoding.
///
/// Prefix assignments follow the official multibase registry:
/// https://github.com/multiformats/multibase/blob/master/multibase.csv
///
/// Encodings that have no official multibase code point (Base62,
/// Base91, Ascii85, Z85, Crockford, Clockwork, DQ) return
/// `Error(UnsupportedMultibaseEncoding)` from `encode_with_prefix`.
import gleam/result
import gleam/string
import yabase/core/dispatcher
import yabase/core/encoding.{
  type CodecError, type Decoded, type Encoding,
  AdobeAscii85 as AdobeAscii85Encoding, Ascii85 as Ascii85Encoding,
  Base16 as Base16Encoding, Base2 as Base2Encoding,
  Base32 as Base32Encoding, Base36 as Base36Encoding,
  Base45 as Base45Encoding, Base58 as Base58Encoding, Base62 as Base62Encoding,
  Bitcoin, Flickr,
  Base64 as Base64Encoding, Base91 as Base91Encoding, Clockwork, Crockford, DQ,
  Decoded, Hex, NoPadding, RFC4648, Rfc1924Base85 as Rfc1924Encoding, Standard,
  UnsupportedMultibaseEncoding, UnsupportedPrefix, UrlSafe, UrlSafeNoPadding,
  Z85 as Z85Encoding, ZBase32,
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
/// See: https://github.com/multiformats/multibase/blob/master/multibase.csv
fn encoding_to_prefix(enc: Encoding) -> Result(String, Nil) {
  case enc {
    // 0 = base2
    Base2Encoding -> Ok("0")
    // f = base16 (lowercase)
    Base16Encoding -> Ok("f")
    // c = base32 padded (lowercase, RFC 4648)
    Base32Encoding(RFC4648) -> Ok("c")
    // t = base32hex padded (lowercase, RFC 4648)
    Base32Encoding(Hex) -> Ok("t")
    // Not in official registry
    Base32Encoding(Crockford) -> Error(Nil)
    Base32Encoding(Clockwork) -> Error(Nil)
    // h = base32z (z-base-32)
    Base32Encoding(ZBase32) -> Ok("h")
    // k = base36 (lowercase)
    Base36Encoding -> Ok("k")
    // R = base45
    Base45Encoding -> Ok("R")
    // z = base58btc
    Base58Encoding(Bitcoin) -> Ok("z")
    // Z = base58flickr
    Base58Encoding(Flickr) -> Ok("Z")
    // Not in official registry
    Base62Encoding -> Error(Nil)
    // M = base64 padded (RFC 4648)
    Base64Encoding(Standard) -> Ok("M")
    // U = base64urlpad (with padding)
    Base64Encoding(UrlSafe) -> Ok("U")
    // m = base64 (no padding)
    Base64Encoding(NoPadding) -> Ok("m")
    // u = base64url (no padding)
    Base64Encoding(UrlSafeNoPadding) -> Ok("u")
    // Not in official registry
    Base64Encoding(DQ) -> Error(Nil)
    Base91Encoding -> Error(Nil)
    Ascii85Encoding -> Error(Nil)
    AdobeAscii85Encoding -> Error(Nil)
    Rfc1924Encoding -> Error(Nil)
    Z85Encoding -> Error(Nil)
  }
}

/// Map a multibase prefix character to its Encoding.
fn prefix_to_encoding(prefix: String) -> Result(Encoding, Nil) {
  case prefix {
    // base2
    "0" -> Ok(Base2Encoding)
    // base16
    "f" | "F" -> Ok(Base16Encoding)
    // base32 padded (RFC 4648)
    "c" | "C" -> Ok(Base32Encoding(RFC4648))
    // b = base32lower (no-padding), B = base32upper (no-padding)
    // Decode as same codec; our decoder accepts both padded and unpadded
    "b" | "B" -> Ok(Base32Encoding(RFC4648))
    // base32hex padded (RFC 4648)
    "t" | "T" -> Ok(Base32Encoding(Hex))
    // base32hex no-padding
    "v" | "V" -> Ok(Base32Encoding(Hex))
    // base36
    "k" | "K" -> Ok(Base36Encoding)
    // R = base45
    "R" -> Ok(Base45Encoding)
    // base58btc
    "z" -> Ok(Base58Encoding(Bitcoin))
    // base58flickr
    "Z" -> Ok(Base58Encoding(Flickr))
    // h = base32z (z-base-32)
    "h" -> Ok(Base32Encoding(ZBase32))
    // M = base64pad (with padding)
    "M" -> Ok(Base64Encoding(Standard))
    // m = base64 (no padding)
    "m" -> Ok(Base64Encoding(NoPadding))
    // U = base64urlpad (with padding)
    "U" -> Ok(Base64Encoding(UrlSafe))
    // u = base64url (no padding)
    "u" -> Ok(Base64Encoding(UrlSafeNoPadding))
    _ -> Error(Nil)
  }
}

fn encoding_name(enc: Encoding) -> String {
  case enc {
    Base2Encoding -> "base2"
    Base16Encoding -> "base16"
    Base32Encoding(RFC4648) -> "base32pad"
    Base32Encoding(Hex) -> "base32hexpad"
    Base32Encoding(Crockford) -> "base32crockford"
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
    Base91Encoding -> "base91"
    Ascii85Encoding -> "ascii85"
    AdobeAscii85Encoding -> "adobe-ascii85"
    Rfc1924Encoding -> "rfc1924-base85"
    Z85Encoding -> "z85"
  }
}
