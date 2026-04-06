/// Base36 encoding (0-9, a-z). Case-insensitive decode.
import gleam/bit_array
import gleam/list
import gleam/string
import yabase/core/encoding.{type CodecError, InvalidCharacter}

const alphabet = "0123456789abcdefghijklmnopqrstuvwxyz"

/// Encode a BitArray to Base36 (lowercase).
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
      let remainder = num % 36
      let char = string_char_at(alphabet, remainder)
      encode_int(num / 36, char <> acc)
    }
  }
}

/// Decode a Base36 string to a BitArray.
pub fn decode(input: String) -> Result(BitArray, CodecError) {
  case input {
    "" -> Ok(<<>>)
    _ -> {
      let lower = string.lowercase(input)
      let leading_zeros = count_leading_char(lower, "0", 0)
      case string_to_int(lower, 0, 0) {
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
        Ok(val) -> string_to_int(rest, acc * 36 + val, pos + 1)
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
    "g" -> Ok(16)
    "h" -> Ok(17)
    "i" -> Ok(18)
    "j" -> Ok(19)
    "k" -> Ok(20)
    "l" -> Ok(21)
    "m" -> Ok(22)
    "n" -> Ok(23)
    "o" -> Ok(24)
    "p" -> Ok(25)
    "q" -> Ok(26)
    "r" -> Ok(27)
    "s" -> Ok(28)
    "t" -> Ok(29)
    "u" -> Ok(30)
    "v" -> Ok(31)
    "w" -> Ok(32)
    "x" -> Ok(33)
    "y" -> Ok(34)
    "z" -> Ok(35)
    _ -> Error(Nil)
  }
}

fn string_char_at(s: String, index: Int) -> String {
  case string.drop_start(s, index) |> string.pop_grapheme {
    Ok(#(c, _)) -> c
    Error(_) -> ""
  }
}
