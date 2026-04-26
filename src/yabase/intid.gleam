//// Integer helpers for short URL-safe identifiers.
////
//// The byte-oriented codecs in `yabase/facade` are the right tool when
//// the input is opaque bytes (hashes, public keys, raw payloads). For
//// the very common short-ID case — DB autoincrement ids, sequence
//// numbers, hash truncations — callers want `Int -> compact string`
//// directly. Without these helpers every project re-implements the
//// same `Int -> big-endian bytes -> trim-leading-zero` shim.
////
//// `encode_int_*` emits canonical form: no leading zero characters
//// beyond what the value itself requires (`encode_int_base58(0) ==
//// "1"`, the alphabet's zero character; `encode_int_base58(58) ==
//// "21"`, no leading `"1"`).
////
//// `decode_int_*` is tolerant of leading zero characters
//// (`decode_int_base58("0042")` and `decode_int_base58("42")` both
//// return the same `Int`), so input from external sources that
//// zero-pads is accepted without ceremony.
////
//// Negative inputs are normalized to `int.absolute_value` before
//// encoding — the magnitude is what gets stored. The decode side
//// always returns a non-negative `Int`.

import gleam/int
import gleam/result
import yabase/base32/crockford as base32_crockford
import yabase/base32/rfc4648 as base32_rfc4648
import yabase/base36
import yabase/base58/bitcoin as base58_bitcoin
import yabase/base58/flickr as base58_flickr
import yabase/base62
import yabase/core/encoding.{type CodecError}
import yabase/internal/bignum

/// Encode a non-negative `Int` as a Base32 (RFC 4648) string.
pub fn encode_int_base32_rfc4648(value: Int) -> String {
  base32_rfc4648.encode(int_to_bytes_be(value))
}

/// Decode a Base32 (RFC 4648) string back to an `Int`.
pub fn decode_int_base32_rfc4648(input: String) -> Result(Int, CodecError) {
  base32_rfc4648.decode(input)
  |> result.map(bytes_to_int)
}

/// Encode a non-negative `Int` as a Crockford Base32 string.
pub fn encode_int_base32_crockford(value: Int) -> String {
  base32_crockford.encode(int_to_bytes_be(value))
}

/// Decode a Crockford Base32 string back to an `Int`.
pub fn decode_int_base32_crockford(input: String) -> Result(Int, CodecError) {
  base32_crockford.decode(input)
  |> result.map(bytes_to_int)
}

/// Encode a non-negative `Int` as a Base36 string.
pub fn encode_int_base36(value: Int) -> String {
  base36.encode(int_to_bytes_be(value))
}

/// Decode a Base36 string back to an `Int`.
pub fn decode_int_base36(input: String) -> Result(Int, CodecError) {
  base36.decode(input)
  |> result.map(bytes_to_int)
}

/// Encode a non-negative `Int` as a Base58 (Bitcoin alphabet) string.
pub fn encode_int_base58(value: Int) -> String {
  base58_bitcoin.encode(int_to_bytes_be(value))
}

/// Decode a Base58 (Bitcoin alphabet) string back to an `Int`.
pub fn decode_int_base58(input: String) -> Result(Int, CodecError) {
  base58_bitcoin.decode(input)
  |> result.map(bytes_to_int)
}

/// Encode a non-negative `Int` as a Base58 (Flickr alphabet) string.
pub fn encode_int_base58_flickr(value: Int) -> String {
  base58_flickr.encode(int_to_bytes_be(value))
}

/// Decode a Base58 (Flickr alphabet) string back to an `Int`.
pub fn decode_int_base58_flickr(input: String) -> Result(Int, CodecError) {
  base58_flickr.decode(input)
  |> result.map(bytes_to_int)
}

/// Encode a non-negative `Int` as a Base62 string.
pub fn encode_int_base62(value: Int) -> String {
  base62.encode(int_to_bytes_be(value))
}

/// Decode a Base62 string back to an `Int`.
pub fn decode_int_base62(input: String) -> Result(Int, CodecError) {
  base62.decode(input)
  |> result.map(bytes_to_int)
}

fn int_to_bytes_be(value: Int) -> BitArray {
  let magnitude = int.absolute_value(value)
  case magnitude {
    0 -> <<0>>
    _ -> accumulate_bytes(magnitude, <<>>)
  }
}

fn accumulate_bytes(num: Int, acc: BitArray) -> BitArray {
  case num {
    0 -> acc
    _ -> {
      let byte = num % 256
      accumulate_bytes(num / 256, <<byte, acc:bits>>)
    }
  }
}

fn bytes_to_int(data: BitArray) -> Int {
  bignum.bytes_to_int(data, 0)
}
