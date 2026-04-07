/// Ascii85 (btoa) encoding.
/// Encodes 4-byte groups into 5 ASCII characters from '!' (33) to 'u' (117).
/// Special case: all-zero groups encode as 'z'.
/// Special case: all-space groups (0x20202020) encode as 'y'.
import gleam/bit_array
import gleam/list
import gleam/string
import yabase/core/encoding.{
  type CodecError, InvalidCharacter, InvalidLength, Overflow,
}

/// Encode a BitArray to Ascii85.
pub fn encode(data: BitArray) -> String {
  encode_groups(data, [])
  |> list.reverse
  |> string.join("")
}

fn encode_groups(data: BitArray, acc: List(String)) -> List(String) {
  case data {
    <<0:32, rest:bits>> -> encode_groups(rest, ["z", ..acc])
    <<0x20, 0x20, 0x20, 0x20, rest:bits>> -> encode_groups(rest, ["y", ..acc])
    <<a:8, b:8, c:8, d:8, rest:bits>> -> {
      let n = a * 16_777_216 + b * 65_536 + c * 256 + d
      let encoded = encode_u32(n, 5, [])
      encode_groups(rest, [chars_to_string(encoded), ..acc])
    }
    <<>> -> acc
    remaining -> {
      let #(padded, original_len) = pad_to_4(remaining, 0)
      case padded {
        <<a:8, b:8, c:8, d:8>> -> {
          let n = a * 16_777_216 + b * 65_536 + c * 256 + d
          let encoded = encode_u32(n, 5, [])
          [chars_to_string(list_take(encoded, original_len + 1)), ..acc]
        }
        _ -> acc
      }
    }
  }
}

fn pad_to_4(data: BitArray, len: Int) -> #(BitArray, Int) {
  case bit_array.byte_size(data) >= 4 {
    True -> #(data, len)
    False ->
      pad_to_4(bit_array.append(data, <<0:8>>), case len {
        0 -> bit_array.byte_size(data)
        _ -> len
      })
  }
}

fn encode_u32(n: Int, count: Int, acc: List(Int)) -> List(Int) {
  case count {
    0 -> acc
    _ -> encode_u32(n / 85, count - 1, [n % 85 + 33, ..acc])
  }
}

fn chars_to_string(chars: List(Int)) -> String {
  case chars {
    [] -> ""
    [c, ..rest] -> {
      let assert Ok(s) = bit_array.to_string(<<c:int>>)
      s <> chars_to_string(rest)
    }
  }
}

fn list_take(l: List(a), n: Int) -> List(a) {
  case n, l {
    0, _ -> []
    _, [] -> []
    _, [h, ..t] -> [h, ..list_take(t, n - 1)]
  }
}

/// Decode an Ascii85 string to a BitArray.
pub fn decode(input: String) -> Result(BitArray, CodecError) {
  decode_groups(input, <<>>, 0)
}

fn decode_groups(
  input: String,
  acc: BitArray,
  pos: Int,
) -> Result(BitArray, CodecError) {
  case string.pop_grapheme(input) {
    Error(Nil) -> Ok(acc)
    Ok(#("z", rest)) ->
      decode_groups(rest, bit_array.append(acc, <<0:32>>), pos + 1)
    Ok(#("y", rest)) ->
      decode_groups(
        rest,
        bit_array.append(acc, <<0x20, 0x20, 0x20, 0x20>>),
        pos + 1,
      )
    Ok(#(c1, r1)) ->
      case take_ascii85_group(c1, r1, pos) {
        Error(e) -> Error(e)
        Ok(#(chars, char_count, rest)) ->
          case char_count < 2 {
            True -> Error(InvalidLength(pos + char_count))
            False -> {
              let padded = pad_ascii85_chars(chars, 5)
              case decode_5_chars(padded) {
                Error(e) -> Error(e)
                Ok(n) ->
                  case n > 4_294_967_295 {
                    True -> Error(Overflow)
                    False -> {
                      let bytes = u32_to_bytes(n)
                      let result_bytes = list_take(bytes, char_count - 1)
                      decode_groups(
                        rest,
                        bit_array.append(
                          acc,
                          list_to_bit_array(result_bytes, <<>>),
                        ),
                        pos + char_count,
                      )
                    }
                  }
              }
            }
          }
      }
  }
}

fn take_ascii85_group(
  first: String,
  input: String,
  pos: Int,
) -> Result(#(List(Int), Int, String), CodecError) {
  case char_to_ascii85_value(first) {
    Error(_) -> Error(InvalidCharacter(first, pos))
    Ok(v) -> collect_group(input, [v], 1, pos + 1)
  }
}

fn collect_group(
  input: String,
  acc: List(Int),
  count: Int,
  pos: Int,
) -> Result(#(List(Int), Int, String), CodecError) {
  case count >= 5 {
    True -> Ok(#(list.reverse(acc), count, input))
    False ->
      case string.pop_grapheme(input) {
        Error(Nil) -> Ok(#(list.reverse(acc), count, ""))
        Ok(#(c, rest)) ->
          case char_to_ascii85_value(c) {
            Error(_) -> Error(InvalidCharacter(c, pos))
            Ok(v) -> collect_group(rest, [v, ..acc], count + 1, pos + 1)
          }
      }
  }
}

fn pad_ascii85_chars(chars: List(Int), target: Int) -> List(Int) {
  case list.length(chars) >= target {
    True -> chars
    False -> pad_ascii85_chars(list.append(chars, [84]), target)
  }
}

fn decode_5_chars(chars: List(Int)) -> Result(Int, CodecError) {
  case chars {
    [a, b, c, d, e] -> {
      let n = a * 52_200_625 + b * 614_125 + c * 7225 + d * 85 + e
      Ok(n)
    }
    _ -> Error(InvalidLength(list.length(chars)))
  }
}

fn u32_to_bytes(n: Int) -> List(Int) {
  [n / 16_777_216 % 256, n / 65_536 % 256, n / 256 % 256, n % 256]
}

fn char_to_ascii85_value(c: String) -> Result(Int, Nil) {
  case string.to_utf_codepoints(c) {
    [cp] -> {
      let code = string.utf_codepoint_to_int(cp)
      case code >= 33 && code <= 117 {
        True -> Ok(code - 33)
        False -> Error(Nil)
      }
    }
    _ -> Error(Nil)
  }
}

fn list_to_bit_array(bytes: List(Int), acc: BitArray) -> BitArray {
  case bytes {
    [] -> acc
    [b, ..rest] -> list_to_bit_array(rest, bit_array.append(acc, <<b:int>>))
  }
}
