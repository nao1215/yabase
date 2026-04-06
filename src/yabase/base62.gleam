/// Base62 encoding (0-9, A-Z, a-z).
import gleam/bit_array
import gleam/list
import gleam/string
import yabase/core/encoding.{type CodecError, InvalidCharacter}

const alphabet = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz"

/// Encode a BitArray to Base62.
pub fn encode(data: BitArray) -> String {
  case bit_array.byte_size(data) {
    0 -> ""
    _ -> {
      let leading_zeros = count_leading_zeros(data, 0)
      let num = bytes_to_int(data, 0)
      case num {
        0 -> string.repeat("0", leading_zeros)
        _ -> string.repeat("0", leading_zeros) <> encode_int(num, "")
      }
    }
  }
}

fn count_leading_zeros(data: BitArray, count: Int) -> Int {
  case data {
    <<0:8, rest:bits>> -> count_leading_zeros(rest, count + 1)
    _ -> count
  }
}

fn bytes_to_int(data: BitArray, acc: Int) -> Int {
  case data {
    <<byte:8, rest:bits>> -> bytes_to_int(rest, acc * 256 + byte)
    _ -> acc
  }
}

fn encode_int(num: Int, acc: String) -> String {
  case num {
    0 -> acc
    _ -> {
      let char = string_char_at(alphabet, num % 62)
      encode_int(num / 62, char <> acc)
    }
  }
}

/// Decode a Base62 string to a BitArray.
pub fn decode(input: String) -> Result(BitArray, CodecError) {
  case input {
    "" -> Ok(<<>>)
    _ -> {
      let leading_zeros = count_leading_char(input, "0", 0)
      case string_to_int(input, 0, 0) {
        Error(e) -> Error(e)
        Ok(num) -> {
          let bytes = int_to_bytes(num, [])
          let leading = list.repeat(0, leading_zeros)
          let all_bytes = list.append(leading, bytes)
          Ok(list_to_bit_array(all_bytes, <<>>))
        }
      }
    }
  }
}

fn count_leading_char(input: String, char: String, count: Int) -> Int {
  case string.pop_grapheme(input) {
    Ok(#(c, rest)) if c == char -> count_leading_char(rest, char, count + 1)
    _ -> count
  }
}

fn string_to_int(input: String, acc: Int, pos: Int) -> Result(Int, CodecError) {
  case string.pop_grapheme(input) {
    Error(Nil) -> Ok(acc)
    Ok(#(c, rest)) ->
      case char_value(c) {
        Error(_) -> Error(InvalidCharacter(c, pos))
        Ok(val) -> string_to_int(rest, acc * 62 + val, pos + 1)
      }
  }
}

fn int_to_bytes(num: Int, acc: List(Int)) -> List(Int) {
  case num {
    0 -> acc
    _ -> int_to_bytes(num / 256, [num % 256, ..acc])
  }
}

fn list_to_bit_array(bytes: List(Int), acc: BitArray) -> BitArray {
  case bytes {
    [] -> acc
    [b, ..rest] -> list_to_bit_array(rest, bit_array.append(acc, <<b:int>>))
  }
}

fn char_value(c: String) -> Result(Int, Nil) {
  find_index(alphabet, c, 0)
}

fn find_index(haystack: String, needle: String, idx: Int) -> Result(Int, Nil) {
  case string.pop_grapheme(haystack) {
    Error(Nil) -> Error(Nil)
    Ok(#(c, rest)) ->
      case c == needle {
        True -> Ok(idx)
        False -> find_index(rest, needle, idx + 1)
      }
  }
}

fn string_char_at(s: String, index: Int) -> String {
  case string.drop_start(s, index) |> string.pop_grapheme {
    Ok(#(c, _)) -> c
    Error(_) -> ""
  }
}
