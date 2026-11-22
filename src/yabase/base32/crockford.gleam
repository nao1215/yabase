/// Crockford's Base32 encoding.
///
/// Encodes data as a number in base 32 per
/// <https://www.crockford.com/base32.html>.
///
/// Alphabet: `0123456789ABCDEFGHJKMNPQRSTVWXYZ`.
/// Case-insensitive decoding. `O`→`0`, `I`/`L`→`1` on decode.
/// Hyphens ignored. No padding.
///
/// Treats the non-zero suffix as a big-endian unsigned integer and
/// preserves each leading zero byte as one '0' character. For example,
/// `encode(<<0, 255, 255, 255, 255>>) == "03ZZZZZZ"`.
/// Use `yabase/base32/rfc4648` for fixed-width 5-bit groups with padding.
import gleam/bit_array
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
/// Preserves leading zero bytes as '0' characters; the remaining length
/// depends on the numeric magnitude. For fixed-width groups, use
/// [`yabase/base32/rfc4648.encode`](./rfc4648.html#encode).
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
/// mapped to the 32-character Crockford alphabet followed by *~$=U.
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
      let check = string.slice(input, length - 1, 1)
      let check = case bit_array.from_string(check) {
        <<_>> -> string.uppercase(check)
        _ -> check
      }
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
