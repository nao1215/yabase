/// Base16 (hexadecimal) encoding and decoding.
///
/// Issue #19: `encode/1` now emits the canonical uppercase form
/// (`0-9 A-F`) per RFC 4648 §8. Use `encode_lowercase/1` for the
/// opt-in lowercase variant. The decoder remains case-insensitive,
/// so round-trips with both encoders work.
import gleam/bit_array
import gleam/int
import gleam/list
import gleam/string
import yabase/core/encoding.{type CodecError, InvalidCharacter, InvalidLength}

/// Encode a BitArray to an uppercase hexadecimal string per
/// RFC 4648 §8 (the canonical Base 16 encoding).
///
/// Use `encode_lowercase/1` when interoperating with tools that
/// emit lowercase hex (e.g. `sha256sum`, IPFS multibase prefix `f`,
/// many JSON Web Token implementations); the decoder accepts either
/// case, so round-trips work in both directions.
pub fn encode(data: BitArray) -> String {
  encode_bytes(data, [], string.uppercase)
  |> list.reverse
  |> string.join("")
}

/// Encode a BitArray to a lowercase hexadecimal string. Use this
/// when interoperating with tools that expect the lowercase variant
/// (`sha256sum` shell output, IPFS multibase prefix `f`, etc.). The
/// canonical RFC 4648 §8 form is uppercase — see `encode/1`.
pub fn encode_lowercase(data: BitArray) -> String {
  encode_bytes(data, [], string.lowercase)
  |> list.reverse
  |> string.join("")
}

fn encode_bytes(
  data: BitArray,
  acc: List(String),
  case_fn: fn(String) -> String,
) -> List(String) {
  case data {
    <<byte:int, rest:bits>> -> {
      let high = int.to_base16(byte / 16)
      let low = int.to_base16(byte % 16)
      encode_bytes(rest, [case_fn(high <> low), ..acc], case_fn)
    }
    _ -> acc
  }
}

/// Decode a hexadecimal string to a BitArray.
pub fn decode(input: String) -> Result(BitArray, CodecError) {
  let chars = string.lowercase(input)
  let len = string.length(chars)
  case len % 2 {
    0 -> decode_pairs(chars, <<>>, 0)
    _ -> Error(InvalidLength(len))
  }
}

fn decode_pairs(
  input: String,
  acc: BitArray,
  pos: Int,
) -> Result(BitArray, CodecError) {
  case string.pop_grapheme(input) {
    Error(Nil) -> Ok(acc)
    Ok(#(c1, rest1)) ->
      case string.pop_grapheme(rest1) {
        Error(Nil) -> Error(InvalidLength(pos + 1))
        Ok(#(c2, rest2)) ->
          case hex_char_to_int(c1), hex_char_to_int(c2) {
            Ok(high), Ok(low) -> {
              let byte = high * 16 + low
              decode_pairs(rest2, bit_array.append(acc, <<byte:int>>), pos + 2)
            }
            Error(_), _ -> Error(InvalidCharacter(c1, pos))
            _, Error(_) -> Error(InvalidCharacter(c2, pos + 1))
          }
      }
  }
}

fn hex_char_to_int(c: String) -> Result(Int, Nil) {
  case c {
    "0" -> Ok(0)
    "1" -> Ok(1)
    "2" -> Ok(2)
    "3" -> Ok(3)
    "4" -> Ok(4)
    "5" -> Ok(5)
    "6" -> Ok(6)
    "7" -> Ok(7)
    "8" -> Ok(8)
    "9" -> Ok(9)
    "a" -> Ok(10)
    "b" -> Ok(11)
    "c" -> Ok(12)
    "d" -> Ok(13)
    "e" -> Ok(14)
    "f" -> Ok(15)
    _ -> Error(Nil)
  }
}
