/// Crockford's Base32 encoding.
///
/// Encodes data as a number in base 32 per
/// <https://www.crockford.com/base32.html>.
///
/// Alphabet: `0123456789ABCDEFGHJKMNPQRSTVWXYZ`.
/// Case-insensitive decoding. `O`→`0`, `I`/`L`→`1` on decode.
/// Hyphens ignored. No padding.
///
/// **Big-integer shape, NOT byte-aligned (issue #22).** This module
/// treats the input `BitArray` as a big-endian unsigned integer and
/// emits the base-32 representation of that integer with leading
/// zeros stripped. The output length therefore depends on the
/// numeric magnitude of the input, not on the input's byte length:
/// 5 random bytes whose top byte is `0x00` round-trip to a
/// 7-character string, while 5 random bytes whose top byte is
/// `0xFF` round-trip to an 8-character string.
///
/// If you want **fixed-length, byte-aligned** Base32 output (the
/// shape callers usually expect from "Base32" — same as ULID /
/// NanoID / Stripe-style IDs), use [`yabase/base32/rfc4648`](./rfc4648.html)
/// instead. RFC 4648 emits exactly `ceil(byte_count * 8 / 5)`
/// characters of output for any input, and pads to a multiple of 8
/// when needed.
///
/// This module is the right pick when you want Crockford's
/// human-typeable alphabet *and* the bignum semantics — for example
/// when encoding a numeric ID that already fits the base-32
/// integer model.
import gleam/string
import yabase/core/error.{type CodecError, InvalidChecksum, InvalidLength}
import yabase/core/guard
import yabase/internal/alphabet
import yabase/internal/bignum

const symbols = "0123456789ABCDEFGHJKMNPQRSTVWXYZ"

const check_symbols = "0123456789ABCDEFGHJKMNPQRSTVWXYZ*~$=U"

fn crockford_alphabet() -> alphabet.Alphabet {
  alphabet.with_extras(
    symbols:,
    folding: alphabet.FoldToUpper,
    aliases: [#("O", 0), #("I", 1), #("L", 1)],
    ignore: "-",
  )
}

/// Encode a BitArray to a Crockford Base32 string (bignum shape).
///
/// The input is treated as a big-endian unsigned integer and
/// converted to base 32 using Crockford's alphabet, with leading
/// zero digits stripped. As a result the output length **varies
/// with the numeric magnitude** of the input, not with its byte
/// length — see the module-level docstring for the implications
/// (issue #22).
///
/// If you want fixed-length 8-character output for every 5-byte
/// input (the byte-aligned framing ULID / NanoID expect), use
/// [`yabase/base32/rfc4648.encode`](../rfc4648.html#encode)
/// instead.
pub fn encode(data: BitArray) -> String {
  guard.assert_byte_aligned(data)
  bignum.encode(data, crockford_alphabet())
}

/// Decode a Crockford Base32 string to a BitArray.
/// Accepts hyphens (ignored). O->0, I/L->1. Case-insensitive.
pub fn decode(input: String) -> Result(BitArray, CodecError) {
  bignum.decode(input, crockford_alphabet())
}

/// Encode a BitArray to Crockford Base32 with a check symbol appended.
/// The check symbol is computed as the numeric value of the data mod 37,
/// mapped to the 37-character check alphabet (0-9A-Z plus *~$=U).
pub fn encode_check(data: BitArray) -> String {
  encode(data) <> check_symbol(data)
}

/// Decode a Crockford Base32 string with check symbol verification.
/// The last character is the check symbol; the rest is the encoded data.
/// Returns Error(InvalidChecksum) if the check symbol does not match.
pub fn decode_check(input: String) -> Result(BitArray, CodecError) {
  let length = string.length(input)
  case length < 1 {
    True -> Error(InvalidLength(0))
    False -> {
      let body = string.slice(input, 0, length - 1)
      let check = string.uppercase(string.slice(input, length - 1, 1))
      case decode(body) {
        Error(error) -> Error(error)
        Ok(data) ->
          case check == check_symbol(data) {
            True -> Ok(data)
            False -> Error(InvalidChecksum)
          }
      }
    }
  }
}

fn check_symbol(data: BitArray) -> String {
  let check_alphabet = alphabet.new(check_symbols, alphabet.FoldToUpper)
  alphabet.to_string([
    alphabet.symbol(check_alphabet, bignum.remainder(data, 37)),
  ])
}
