/// Z85 encoding (ZeroMQ variant of Ascii85).
/// Alphabet: 0-9, a-z, A-Z, ., -, :, +, =, ^, !, /, *, ?, &, <, >, (, ), [, ], {, }, @, %, $, #
/// Input length for encode MUST be a multiple of 4.
import gleam/bit_array
import gleam/list
import gleam/string
import yabase/core/error.{
  type CodecError, InvalidCharacter, InvalidLength, Overflow,
}

const alphabet = "0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ.-:+=^!/*?&<>()[]{}@%$#"

/// Encode a BitArray to Z85.
/// Returns Error(InvalidLength) if input length is not a multiple of 4.
pub fn encode(data: BitArray) -> Result(String, CodecError) {
  let len = bit_array.byte_size(data)
  case len % 4 {
    0 ->
      Ok(
        encode_groups(data, [])
        |> list.reverse
        |> string.join(""),
      )
    _ -> Error(InvalidLength(len))
  }
}

fn encode_groups(data: BitArray, acc: List(String)) -> List(String) {
  case data {
    <<a:8, b:8, c:8, d:8, rest:bits>> -> {
      let value = a * 16_777_216 + b * 65_536 + c * 256 + d
      let encoded = encode_u32(value, 5, [])
      encode_groups(rest, [list_to_string(encoded), ..acc])
    }
    _ -> acc
  }
}

fn encode_u32(n: Int, count: Int, acc: List(String)) -> List(String) {
  case count {
    0 -> acc
    _ -> {
      let char = string_char_at(alphabet, n % 85)
      encode_u32(n / 85, count - 1, [char, ..acc])
    }
  }
}

fn list_to_string(chars: List(String)) -> String {
  string.join(chars, "")
}

/// Decode a Z85 string to a BitArray.
/// Input length must be a multiple of 5.
pub fn decode(input: String) -> Result(BitArray, CodecError) {
  let len = string.length(input)
  case len % 5 {
    0 -> decode_groups(input, <<>>, 0)
    _ -> Error(InvalidLength(len))
  }
}

fn decode_groups(
  input: String,
  acc: BitArray,
  pos: Int,
) -> Result(BitArray, CodecError) {
  case take_5(input) {
    Error(Nil) -> Ok(acc)
    Ok(#(chars, rest)) ->
      case decode_5_chars(chars, pos) {
        Error(e) -> Error(e)
        Ok(n) -> {
          let bytes = u32_to_bytes(n)
          decode_groups(
            rest,
            bit_array.append(acc, list_to_bit_array(bytes, <<>>)),
            pos + 5,
          )
        }
      }
  }
}

fn take_5(input: String) -> Result(#(List(String), String), Nil) {
  take_n(input, 5, [])
}

fn take_n(
  input: String,
  n: Int,
  acc: List(String),
) -> Result(#(List(String), String), Nil) {
  case n {
    0 -> Ok(#(list.reverse(acc), input))
    _ ->
      case string.pop_grapheme(input) {
        Error(Nil) ->
          case acc {
            [] -> Error(Nil)
            _ -> Error(Nil)
          }
        Ok(#(c, rest)) -> take_n(rest, n - 1, [c, ..acc])
      }
  }
}

/// Maximum value for a Z85-decoded 5-character group: 2^32 - 1
const max_u32 = 4_294_967_295

fn decode_5_chars(chars: List(String), pos: Int) -> Result(Int, CodecError) {
  case decode_5_acc(chars, 0, pos) {
    Ok(n) if n > max_u32 -> Error(Overflow)
    other -> other
  }
}

fn decode_5_acc(
  chars: List(String),
  acc: Int,
  pos: Int,
) -> Result(Int, CodecError) {
  case chars {
    [] -> Ok(acc)
    [c, ..rest] ->
      case char_value(c) {
        Error(Nil) -> Error(InvalidCharacter(c, pos))
        Ok(v) -> decode_5_acc(rest, acc * 85 + v, pos + 1)
      }
  }
}

fn u32_to_bytes(n: Int) -> List(Int) {
  [n / 16_777_216 % 256, n / 65_536 % 256, n / 256 % 256, n % 256]
}

fn char_value(c: String) -> Result(Int, Nil) {
  find_index(alphabet, c, 0)
}

fn find_index(haystack: String, needle: String, idx: Int) -> Result(Int, Nil) {
  case string.pop_grapheme(haystack) {
    Error(Nil) -> Error(Nil)
    Ok(#(ch, rest)) ->
      case ch == needle {
        True -> Ok(idx)
        False -> find_index(rest, needle, idx + 1)
      }
  }
}

fn string_char_at(s: String, index: Int) -> String {
  case string.drop_start(s, index) |> string.pop_grapheme {
    Ok(#(c, _)) -> c
    Error(error) -> {
      let _nil_error = error
      ""
    }
  }
}

fn list_to_bit_array(bytes: List(Int), acc: BitArray) -> BitArray {
  case bytes {
    [] -> acc
    [b, ..rest] -> list_to_bit_array(rest, bit_array.append(acc, <<b:int>>))
  }
}
