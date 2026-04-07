/// Shared big-integer utilities for radix-based encodings
/// (Base8, Base10, Base36, Base58, Base62).
import gleam/bit_array
import gleam/list
import gleam/string
import yabase/core/encoding.{type CodecError, InvalidCharacter}

/// Convert a BitArray to a big integer (MSB first).
pub fn bytes_to_int(data: BitArray, acc: Int) -> Int {
  case data {
    <<byte:8, rest:bits>> -> bytes_to_int(rest, acc * 256 + byte)
    _ -> acc
  }
}

/// Convert a big integer to a list of bytes (MSB first).
pub fn int_to_bytes(num: Int, acc: List(Int)) -> List(Int) {
  case num {
    0 -> acc
    _ -> int_to_bytes(num / 256, [num % 256, ..acc])
  }
}

/// Count leading zero bytes in a BitArray.
pub fn count_leading_zeros(data: BitArray, count: Int) -> Int {
  case data {
    <<0:8, rest:bits>> -> count_leading_zeros(rest, count + 1)
    _ -> count
  }
}

/// Count leading occurrences of a specific character in a string.
pub fn count_leading_char(input: String, char: String, count: Int) -> Int {
  case string.pop_grapheme(input) {
    Ok(#(c, rest)) if c == char -> count_leading_char(rest, char, count + 1)
    _ -> count
  }
}

/// Convert a list of byte values to a BitArray.
pub fn list_to_bit_array(bytes: List(Int), acc: BitArray) -> BitArray {
  case bytes {
    [] -> acc
    [b, ..rest] -> list_to_bit_array(rest, bit_array.append(acc, <<b:int>>))
  }
}

/// Encode a big integer in the given radix using the given alphabet string.
pub fn encode_int(num: Int, radix: Int, alphabet: String, acc: String) -> String {
  case num {
    0 -> acc
    _ -> {
      let remainder = num % radix
      let char = string_char_at(alphabet, remainder)
      encode_int(num / radix, radix, alphabet, char <> acc)
    }
  }
}

/// Decode a string of digits in the given radix, using a char_value function.
pub fn string_to_int(
  input: String,
  radix: Int,
  char_value: fn(String) -> Result(Int, Nil),
  acc: Int,
  pos: Int,
) -> Result(Int, CodecError) {
  case string.pop_grapheme(input) {
    Error(Nil) -> Ok(acc)
    Ok(#(c, rest)) ->
      case char_value(c) {
        Error(_) -> Error(InvalidCharacter(c, pos))
        Ok(val) ->
          string_to_int(rest, radix, char_value, acc * radix + val, pos + 1)
      }
  }
}

/// Encode a BitArray using big-integer radix conversion.
/// zero_char is the character representing 0 in the alphabet.
pub fn encode(data: BitArray, radix: Int, alphabet: String) -> String {
  case bit_array.byte_size(data) {
    0 -> ""
    _ -> {
      let zero_char = string_char_at(alphabet, 0)
      let lz = count_leading_zeros(data, 0)
      let num = bytes_to_int(data, 0)
      case num {
        0 -> string.repeat(zero_char, lz)
        _ ->
          string.repeat(zero_char, lz) <> encode_int(num, radix, alphabet, "")
      }
    }
  }
}

/// Decode a string using big-integer radix conversion.
/// zero_char is the character representing 0 in the alphabet.
pub fn decode(
  input: String,
  radix: Int,
  zero_char: String,
  char_value: fn(String) -> Result(Int, Nil),
) -> Result(BitArray, CodecError) {
  case input {
    "" -> Ok(<<>>)
    _ -> {
      let leading_zeros = count_leading_char(input, zero_char, 0)
      case string_to_int(input, radix, char_value, 0, 0) {
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

fn string_char_at(s: String, index: Int) -> String {
  case string.drop_start(s, index) |> string.pop_grapheme {
    Ok(#(c, _)) -> c
    Error(_) -> ""
  }
}
