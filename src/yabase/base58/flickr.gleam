/// Base58 encoding (Flickr alphabet).
/// Alphabet: 123456789abcdefghijkmnopqrstuvwxyzABCDEFGHJKLMNPQRSTUVWXYZ
/// Same as Bitcoin but with swapped upper/lower case.
import gleam/bit_array
import gleam/list
import gleam/string
import yabase/core/encoding.{type CodecError, InvalidCharacter}

const alphabet = "123456789abcdefghijkmnopqrstuvwxyzABCDEFGHJKLMNPQRSTUVWXYZ"

/// Encode a BitArray to Base58 (Flickr).
pub fn encode(data: BitArray) -> String {
  let leading_zeros = count_leading_zeros(data, 0)
  let num = bytes_to_int(data, 0)
  let encoded = encode_int(num, "")
  string.repeat("1", leading_zeros) <> encoded
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
      let remainder = num % 58
      let char = string_char_at(alphabet, remainder)
      encode_int(num / 58, char <> acc)
    }
  }
}

/// Decode a Base58 string (Flickr alphabet) to a BitArray.
pub fn decode(input: String) -> Result(BitArray, CodecError) {
  let leading_ones = count_leading_char(input, "1", 0)
  case string_to_int(input, 0, 0) {
    Error(e) -> Error(e)
    Ok(num) -> {
      let bytes = int_to_bytes(num, [])
      let leading = list.repeat(0, leading_ones)
      let all_bytes = list.append(leading, bytes)
      Ok(list_to_bit_array(all_bytes, <<>>))
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
        Ok(val) -> string_to_int(rest, acc * 58 + val, pos + 1)
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
