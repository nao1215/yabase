/// Base2 encoding (binary string representation).
/// Each byte is represented as 8 characters of "0" and "1".
import gleam/string
import yabase/core/encoding.{type CodecError, InvalidCharacter, InvalidLength}

/// Encode a BitArray to a binary string (e.g. <<0x41>> -> "01000001").
pub fn encode(data: BitArray) -> String {
  encode_bytes(data, "")
}

fn encode_bytes(data: BitArray, acc: String) -> String {
  case data {
    <<byte:8, rest:bits>> -> encode_bytes(rest, acc <> encode_byte(byte, 7, ""))
    _ -> acc
  }
}

fn encode_byte(byte: Int, bit: Int, acc: String) -> String {
  case bit < 0 {
    True -> acc
    False -> {
      let c = case byte / pow2(bit) % 2 {
        1 -> "1"
        _ -> "0"
      }
      encode_byte(byte, bit - 1, acc <> c)
    }
  }
}

fn pow2(n: Int) -> Int {
  case n {
    0 -> 1
    1 -> 2
    2 -> 4
    3 -> 8
    4 -> 16
    5 -> 32
    6 -> 64
    7 -> 128
    _ -> 1
  }
}

/// Decode a binary string to a BitArray.
/// Input length must be a multiple of 8. Only "0" and "1" are valid.
pub fn decode(input: String) -> Result(BitArray, CodecError) {
  let len = string.length(input)
  case len % 8 {
    0 -> decode_chars(input, <<>>, 0)
    _ -> Error(InvalidLength(len))
  }
}

fn decode_chars(
  input: String,
  acc: BitArray,
  pos: Int,
) -> Result(BitArray, CodecError) {
  case string.length(input) {
    0 -> Ok(acc)
    _ -> decode_byte(input, acc, pos, 0, 0)
  }
}

fn decode_byte(
  input: String,
  acc: BitArray,
  pos: Int,
  byte: Int,
  count: Int,
) -> Result(BitArray, CodecError) {
  case count >= 8 {
    True ->
      decode_chars(input, <<acc:bits, byte:8>>, pos)
    False ->
      case string.pop_grapheme(input) {
        Error(Nil) -> Ok(<<acc:bits, byte:8>>)
        Ok(#(c, rest)) ->
          case c {
            "0" -> decode_byte(rest, acc, pos + 1, byte * 2, count + 1)
            "1" -> decode_byte(rest, acc, pos + 1, byte * 2 + 1, count + 1)
            _ -> Error(InvalidCharacter(c, pos))
          }
      }
  }
}
