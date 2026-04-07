/// z-base-32 encoding.
/// Human-oriented alphabet optimized for readability.
/// Alphabet: ybndrfg8ejkmcpqxot1uwisza345h769
/// No padding.
import gleam/bit_array
import gleam/string
import yabase/core/encoding.{type CodecError, InvalidCharacter, InvalidLength}

const alphabet = "ybndrfg8ejkmcpqxot1uwisza345h769"

/// Encode a BitArray to z-base-32 (no padding).
pub fn encode(data: BitArray) -> String {
  encode_bits(data, [])
  |> list_reverse
  |> string.join("")
}

fn encode_bits(data: BitArray, acc: List(String)) -> List(String) {
  case data {
    <<a:5, rest:bits>> -> {
      let char = string_char_at(alphabet, a)
      encode_bits(rest, [char, ..acc])
    }
    <<a:4>> -> [string_char_at(alphabet, a * 2), ..acc]
    <<a:3>> -> [string_char_at(alphabet, a * 4), ..acc]
    <<a:2>> -> [string_char_at(alphabet, a * 8), ..acc]
    <<a:1>> -> [string_char_at(alphabet, a * 16), ..acc]
    _ -> acc
  }
}

/// Decode a z-base-32 string to a BitArray.
pub fn decode(input: String) -> Result(BitArray, CodecError) {
  let lower = string.lowercase(input)
  let len = string.length(lower)
  case len % 8 {
    1 | 3 | 6 -> Error(InvalidLength(len))
    _ -> decode_chars(lower, <<>>, 0)
  }
}

fn decode_chars(
  input: String,
  acc: BitArray,
  pos: Int,
) -> Result(BitArray, CodecError) {
  case string.pop_grapheme(input) {
    Error(Nil) -> extract_bytes(acc, <<>>)
    Ok(#(c, rest)) ->
      case char_to_value(c) {
        Error(_) -> Error(InvalidCharacter(c, pos))
        Ok(val) -> decode_chars(rest, bit_array.append(acc, <<val:5>>), pos + 1)
      }
  }
}

fn extract_bytes(bits: BitArray, acc: BitArray) -> Result(BitArray, CodecError) {
  case bits {
    <<byte:8, rest:bits>> ->
      extract_bytes(rest, bit_array.append(acc, <<byte:int>>))
    _ -> Ok(acc)
  }
}

fn char_to_value(c: String) -> Result(Int, Nil) {
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
    Error(_) -> ""
  }
}

fn list_reverse(l: List(a)) -> List(a) {
  list_reverse_acc(l, [])
}

fn list_reverse_acc(l: List(a), acc: List(a)) -> List(a) {
  case l {
    [] -> acc
    [h, ..t] -> list_reverse_acc(t, [h, ..acc])
  }
}
