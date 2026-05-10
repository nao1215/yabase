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
//// ## Negative inputs are silently absolutized
////
//// Every `encode_int_*` function in this module accepts any `Int`
//// — including negatives — and normalizes the input to
//// `int.absolute_value` before encoding. The magnitude is what gets
//// stored. The decode side always returns a non-negative `Int`.
////
//// **This is intentional, not a bug, but it is a footgun.** Two
//// distinct inputs (`-1` and `1`) round-trip to the same `Int`,
//// breaking bijection. Code that compares a re-encoded value to its
//// source can match where you would expect a mismatch. If your
//// caller path can produce negative values (offsets that subtracted
//// past zero, Posix timestamps from before 1970, deliberate
//// `-1` sentinels), the safer pattern is to validate the sign at
//// the boundary before reaching `encode_int_*`:
////
//// ```gleam
//// case n >= 0 {
////   True -> Ok(encode_int_base32_crockford(n))
////   False -> Error(MyDomainError.NegativeId(n))
//// }
//// ```
////
//// We intentionally chose silent absolutization over `Result` /
//// `panic` for ergonomics — almost every realistic short-ID caller
//// reaches `encode_int_*` with a value that is already non-negative
//// (DB autoincrement, hash truncation, sequence number), and forcing
//// `Result` everywhere added boilerplate without preventing real
//// bugs. Tracked in #84.
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
import yabase/base10
import yabase/base32/crockford as base32_crockford
import yabase/base32/rfc4648 as base32_rfc4648
import yabase/base36
import yabase/base58/bitcoin as base58_bitcoin
import yabase/base58/flickr as base58_flickr
import yabase/base58check
import yabase/base62
import yabase/core/error.{
  type CodecError as CoreCodecError, InvalidLength, Overflow,
}
import yabase/internal/bignum

/// Issue #74: every `decode_int_*` function in this module returns
/// `Result(Int, CodecError)`. Without this re-export, callers who only
/// `import yabase/intid` cannot type-annotate a wrapper around a
/// decode call without reaching into `yabase/core/error` — a module
/// the README does not mention. The alias keeps the type identity
/// (it's the same `CodecError` the underlying codec functions
/// already use) so error values flow through unchanged.
pub type CodecError =
  CoreCodecError

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

/// Encode an `Int` as a Base32 (RFC 4648) string. Negative inputs
/// are normalized to `int.absolute_value`; see the module note on
/// "Negative inputs are silently absolutized" for the rationale and
/// the recommended boundary-check pattern.
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

/// Encode an `Int` as a Crockford Base32 string. Negative inputs
/// are normalized to `int.absolute_value`; see the module note on
/// "Negative inputs are silently absolutized".
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

/// Encode an `Int` as a Base10 (decimal) string. Negative inputs
/// are normalized to `int.absolute_value`; see the module note on
/// "Negative inputs are silently absolutized".
///
/// Behaviour matches `int.to_string` for the typical case
/// (positive integers) and the rest of the `intid` family for the
/// switch-case bench harnesses described in #78. Routing through
/// `base10.encode` keeps the contract uniform with the other
/// `encode_int_*` functions: a non-negative `Int` in, a string
/// in the alphabet out, no padding.
pub fn encode_int_base10(value: Int) -> String {
  base10.encode(int_to_bytes_be(value))
}

/// Decode a Base10 (decimal) string back to an `Int`.
pub fn decode_int_base10(input: String) -> Result(Int, CodecError) {
  use input <- result.try(reject_empty(input))
  base10.decode(input)
  |> result.map(bytes_to_int)
}

/// Decode a Base10 (decimal) string back to an `Int`, rejecting
/// values greater than `max` with `Error(Overflow)`.
pub fn decode_int_base10_bounded(
  input input: String,
  max max: Int,
) -> Result(Int, CodecError) {
  use value <- result.try(decode_int_base10(input))
  bound_check(value, max)
}

/// Encode an `Int` as a Base36 string. Negative inputs are
/// normalized to `int.absolute_value`; see the module note on
/// "Negative inputs are silently absolutized".
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

/// Encode an `Int` as a Base58 (Bitcoin alphabet) string. Negative
/// inputs are normalized to `int.absolute_value`; see the module
/// note on "Negative inputs are silently absolutized".
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

/// Encode an `Int` as a Base58 (Flickr alphabet) string. Negative
/// inputs are normalized to `int.absolute_value`; see the module
/// note on "Negative inputs are silently absolutized".
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

/// Encode a non-negative `Int` as a Crockford Base32 string with a
/// trailing checksum symbol (Douglas Crockford's optional check
/// character).
///
/// Issue #73: same shape as `encode_int_base32_crockford` but with
/// the typo-resistance guard the underlying codec already supports.
/// Use the matching `decode_int_base32_crockford_check` to recover
/// the integer; the decoder verifies the symbol and returns
/// `Error(InvalidChecksum)` if the input was mistyped.
pub fn encode_int_base32_crockford_check(value: Int) -> String {
  base32_crockford.encode_check(int_to_bytes_be(value))
}

/// Decode a checksummed Crockford Base32 string back to an `Int`,
/// verifying the trailing check symbol.
pub fn decode_int_base32_crockford_check(
  input: String,
) -> Result(Int, CodecError) {
  use input <- result.try(reject_empty(input))
  base32_crockford.decode_check(input)
  |> result.map(bytes_to_int)
}

/// Decode a checksummed Crockford Base32 string back to an `Int`,
/// rejecting values greater than `max` with `Error(Overflow)`.
pub fn decode_int_base32_crockford_check_bounded(
  input input: String,
  max max: Int,
) -> Result(Int, CodecError) {
  use value <- result.try(decode_int_base32_crockford_check(input))
  bound_check(value, max)
}

/// Encode a non-negative `Int` as a Base58Check string (Bitcoin's
/// double-SHA-256 checksum format).
///
/// Issue #73: this is the int-typed counterpart of
/// `yabase/base58check.encode/2`. Version is fixed at `0`
/// (Bitcoin mainnet P2PKH) — callers that need a different version
/// should reach for `yabase/base58check.encode/2` directly with their
/// own `BitArray` payload.
///
/// Returns the canonical Base58Check string. The underlying
/// `yabase/base58check.encode` only errors on out-of-range version
/// bytes (this helper hard-codes a valid one), so this signature
/// does not surface a `Result`.
pub fn encode_int_base58check(value: Int) -> String {
  base58check.encode(0, int_to_bytes_be(value))
  |> result.unwrap("")
}

/// Decode a Base58Check string back to an `Int`, verifying the
/// 4-byte SHA-256 checksum.
///
/// Issue #73: returns the *payload* as an `Int`, ignoring the version
/// byte (which `encode_int_base58check` always sets to `0`).
/// Callers that need to inspect the version byte should reach for
/// `yabase/base58check.decode/1` directly.
pub fn decode_int_base58check(input: String) -> Result(Int, CodecError) {
  use input <- result.try(reject_empty(input))
  case base58check.decode(input) {
    Error(e) -> Error(e)
    Ok(decoded) -> Ok(bytes_to_int(decoded.payload))
  }
}

/// Decode a Base58Check string back to an `Int`, rejecting payload
/// values greater than `max` with `Error(Overflow)`. The checksum is
/// verified before the bounds check, so a corrupted input fails as
/// `InvalidChecksum` rather than `Overflow`.
pub fn decode_int_base58check_bounded(
  input input: String,
  max max: Int,
) -> Result(Int, CodecError) {
  use value <- result.try(decode_int_base58check(input))
  bound_check(value, max)
}

/// Encode an `Int` as a Base62 string. Negative inputs are
/// normalized to `int.absolute_value`; see the module note on
/// "Negative inputs are silently absolutized".
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
