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
//// `decode_int_*` rejects the empty string with
//// `Error(InvalidLength(0))` rather than treating it as zero. Callers
//// can therefore distinguish "no ID was supplied" from "the ID is
//// zero" — important for URL routing, form parsing, and database
//// lookups. The byte-oriented decoders in `yabase/facade` retain the
//// `Ok(<<>>)` round-trip behavior for empty input.
////
//// Negative inputs are normalized to `int.absolute_value` before
//// encoding — the magnitude is what gets stored. The decode side
//// always returns a non-negative `Int`.
////
//// ## Bounded decode
////
//// `decode_int_*` accepts inputs of any length, so the decoded
//// `Int` can exceed any fixed integer width — Erlang `Int` is a
//// bignum. Realistic backing stores cap IDs at 64 bits (SQLite
//// `INTEGER`, Postgres `bigserial`, MySQL `BIGINT`), so feeding an
//// unbounded `decode_int_*` result into one of those columns
//// crashes the driver as soon as a user supplies a slightly-too-long
//// string. For the same reason, JavaScript-target callers cap at
//// 53 bits (`Number.MAX_SAFE_INTEGER`).
////
//// Use `decode_int_*_bounded(input:, max:)` whenever the decoded value
//// flows into a fixed-width sink. The bounded variants return
//// `Error(Overflow)` if the decoded `Int` exceeds `max`. Common caps
//// are exported as `int64_max` (signed 64-bit, `2^63 - 1`) and
//// `int53_max` (JS-safe integer, `2^53 - 1`).

import gleam/bool
import gleam/int
import gleam/result
import gleam/string
import yabase/base32/crockford as base32_crockford
import yabase/base32/rfc4648 as base32_rfc4648
import yabase/base36
import yabase/base58/bitcoin as base58_bitcoin
import yabase/base58/flickr as base58_flickr
import yabase/base62
import yabase/core/error.{type CodecError, InvalidLength, Overflow}
import yabase/internal/bignum

/// Largest value that fits in a signed 64-bit integer (`2^63 - 1`).
/// Use as the `max` argument to `decode_int_*_bounded` when the
/// decoded value flows into a column declared `BIGINT` (Postgres,
/// MySQL) or `INTEGER` (SQLite).
pub const int64_max: Int = 9_223_372_036_854_775_807

/// Largest value that round-trips losslessly through a JavaScript
/// `number` (`2^53 - 1`, `Number.MAX_SAFE_INTEGER`). Use as the
/// `max` argument to `decode_int_*_bounded` when the decoded value
/// is passed across a JS-target boundary or serialized as JSON for
/// a JavaScript consumer.
pub const int53_max: Int = 9_007_199_254_740_991

/// Encode a non-negative `Int` as a Base32 (RFC 4648) string.
pub fn encode_int_base32_rfc4648(value: Int) -> String {
  base32_rfc4648.encode(int_to_bytes_be(value))
}

/// Decode a Base32 (RFC 4648) string back to an `Int`.
pub fn decode_int_base32_rfc4648(input: String) -> Result(Int, CodecError) {
  use input <- result.try(reject_empty(input))
  base32_rfc4648.decode(input)
  |> result.map(bytes_to_int)
}

/// Decode a Base32 (RFC 4648) string back to an `Int`, rejecting
/// values greater than `max` with `Error(Overflow)`.
pub fn decode_int_base32_rfc4648_bounded(
  input input: String,
  max max: Int,
) -> Result(Int, CodecError) {
  use value <- result.try(decode_int_base32_rfc4648(input))
  bound_check(value, max)
}

/// Encode a non-negative `Int` as a Crockford Base32 string.
pub fn encode_int_base32_crockford(value: Int) -> String {
  base32_crockford.encode(int_to_bytes_be(value))
}

/// Decode a Crockford Base32 string back to an `Int`.
pub fn decode_int_base32_crockford(input: String) -> Result(Int, CodecError) {
  use input <- result.try(reject_empty(input))
  base32_crockford.decode(input)
  |> result.map(bytes_to_int)
}

/// Decode a Crockford Base32 string back to an `Int`, rejecting
/// values greater than `max` with `Error(Overflow)`.
pub fn decode_int_base32_crockford_bounded(
  input input: String,
  max max: Int,
) -> Result(Int, CodecError) {
  use value <- result.try(decode_int_base32_crockford(input))
  bound_check(value, max)
}

/// Encode a non-negative `Int` as a Base36 string.
pub fn encode_int_base36(value: Int) -> String {
  base36.encode(int_to_bytes_be(value))
}

/// Decode a Base36 string back to an `Int`.
pub fn decode_int_base36(input: String) -> Result(Int, CodecError) {
  use input <- result.try(reject_empty(input))
  base36.decode(input)
  |> result.map(bytes_to_int)
}

/// Decode a Base36 string back to an `Int`, rejecting values
/// greater than `max` with `Error(Overflow)`.
pub fn decode_int_base36_bounded(
  input input: String,
  max max: Int,
) -> Result(Int, CodecError) {
  use value <- result.try(decode_int_base36(input))
  bound_check(value, max)
}

/// Encode a non-negative `Int` as a Base58 (Bitcoin alphabet) string.
pub fn encode_int_base58(value: Int) -> String {
  base58_bitcoin.encode(int_to_bytes_be(value))
}

/// Decode a Base58 (Bitcoin alphabet) string back to an `Int`.
pub fn decode_int_base58(input: String) -> Result(Int, CodecError) {
  use input <- result.try(reject_empty(input))
  base58_bitcoin.decode(input)
  |> result.map(bytes_to_int)
}

/// Decode a Base58 (Bitcoin alphabet) string back to an `Int`,
/// rejecting values greater than `max` with `Error(Overflow)`.
pub fn decode_int_base58_bounded(
  input input: String,
  max max: Int,
) -> Result(Int, CodecError) {
  use value <- result.try(decode_int_base58(input))
  bound_check(value, max)
}

/// Encode a non-negative `Int` as a Base58 (Flickr alphabet) string.
pub fn encode_int_base58_flickr(value: Int) -> String {
  base58_flickr.encode(int_to_bytes_be(value))
}

/// Decode a Base58 (Flickr alphabet) string back to an `Int`.
pub fn decode_int_base58_flickr(input: String) -> Result(Int, CodecError) {
  use input <- result.try(reject_empty(input))
  base58_flickr.decode(input)
  |> result.map(bytes_to_int)
}

/// Decode a Base58 (Flickr alphabet) string back to an `Int`,
/// rejecting values greater than `max` with `Error(Overflow)`.
pub fn decode_int_base58_flickr_bounded(
  input input: String,
  max max: Int,
) -> Result(Int, CodecError) {
  use value <- result.try(decode_int_base58_flickr(input))
  bound_check(value, max)
}

/// Encode a non-negative `Int` as a Base62 string.
pub fn encode_int_base62(value: Int) -> String {
  base62.encode(int_to_bytes_be(value))
}

/// Decode a Base62 string back to an `Int`.
pub fn decode_int_base62(input: String) -> Result(Int, CodecError) {
  use input <- result.try(reject_empty(input))
  base62.decode(input)
  |> result.map(bytes_to_int)
}

/// Decode a Base62 string back to an `Int`, rejecting values
/// greater than `max` with `Error(Overflow)`.
pub fn decode_int_base62_bounded(
  input input: String,
  max max: Int,
) -> Result(Int, CodecError) {
  use value <- result.try(decode_int_base62(input))
  bound_check(value, max)
}

// `decode_int_*` rejects the empty string so callers can distinguish
// "no input" from a zero-valued ID. The byte-oriented decoders keep
// their `Ok(<<>>)` semantics for round-tripping empty inputs.
fn reject_empty(input: String) -> Result(String, CodecError) {
  use <- bool.guard(
    when: string.is_empty(input),
    return: Error(InvalidLength(0)),
  )
  Ok(input)
}

fn bound_check(value: Int, max: Int) -> Result(Int, CodecError) {
  use <- bool.guard(when: value > max, return: Error(Overflow))
  Ok(value)
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
