/// Base45 encoding per RFC 9285.
/// Alphabet: 0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ $%*+-./:
import gleam/bit_array
import gleam/list
import yabase/core/error.{type CodecError, InvalidLength, Overflow}
import yabase/core/guard
import yabase/internal/alphabet.{type Alphabet}

fn base45() -> Alphabet {
  alphabet.new(
    "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ $%*+-./:",
    alphabet.CaseSensitive,
  )
}

/// Encode a BitArray to Base45.
///
/// Sub-byte input panics; see
/// `yabase/core/guard.assert_byte_aligned`.
pub fn encode(data: BitArray) -> String {
  guard.assert_byte_aligned(data)
  encode_loop(data, base45(), [])
}

fn encode_loop(data: BitArray, alphabet: Alphabet, acc: List(Int)) -> String {
  case data {
    <<value:16, rest:bytes>> ->
      encode_loop(rest, alphabet, [
        alphabet.symbol(alphabet, value / 2025),
        alphabet.symbol(alphabet, value / 45 % 45),
        alphabet.symbol(alphabet, value % 45),
        ..acc
      ])
    <<value>> ->
      [
        alphabet.symbol(alphabet, value / 45),
        alphabet.symbol(alphabet, value % 45),
        ..acc
      ]
      |> list.reverse
      |> alphabet.to_string
    _ -> alphabet.to_string(list.reverse(acc))
  }
}

/// Decode a Base45 string to a BitArray.
pub fn decode(input: String) -> Result(BitArray, CodecError) {
  let bytes = bit_array.from_string(input)
  let length = alphabet.character_count(input, bytes)
  case length % 3 {
    1 -> Error(InvalidLength(length))
    _ -> decode_loop(bytes, bytes, base45(), 0, [])
  }
}

fn decode_loop(
  input: BitArray,
  rest: BitArray,
  alphabet: Alphabet,
  offset: Int,
  acc: List(BitArray),
) -> Result(BitArray, CodecError) {
  case rest {
    <<c, d, e, rest:bytes>> ->
      case digits([c, d, e], alphabet, offset, 0, 1) {
        Ok(value) if value > 65_535 -> Error(Overflow)
        Ok(value) ->
          decode_loop(input, rest, alphabet, offset + 3, [<<value:16>>, ..acc])
        Error(bad) ->
          Error(alphabet.invalid_character(alphabet, input, bad, bad))
      }
    <<c, d>> ->
      case digits([c, d], alphabet, offset, 0, 1) {
        Ok(value) if value > 255 -> Error(Overflow)
        Ok(value) -> Ok(bit_array.concat(list.reverse([<<value>>, ..acc])))
        Error(bad) ->
          Error(alphabet.invalid_character(alphabet, input, bad, bad))
      }
    _ -> Ok(bit_array.concat(list.reverse(acc)))
  }
}

/// The value of base-45 digits written least significant first, or the
/// offset of the first byte that is not a symbol.
fn digits(
  group: List(Int),
  alphabet: Alphabet,
  offset: Int,
  value: Int,
  weight: Int,
) -> Result(Int, Int) {
  case group {
    [] -> Ok(value)
    [byte, ..rest] ->
      case alphabet.lookup(alphabet, byte) {
        alphabet.Value(digit) ->
          digits(
            rest,
            alphabet,
            offset + 1,
            value + digit * weight,
            weight * 45,
          )
        alphabet.Ignored | alphabet.Invalid -> Error(offset)
      }
  }
}
