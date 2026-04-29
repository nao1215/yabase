/// Adobe Ascii85 encoding (used in PDF/PostScript).
/// Same encoding as btoa Ascii85 but wrapped in <~ ~> delimiters.
/// All-zero 4-byte groups encode as 'z'.
import gleam/bit_array
import gleam/bool
import gleam/list
import gleam/string
import yabase/core/error.{
  type CodecError, InvalidCharacter, InvalidLength, Overflow,
}

const prefix = "<~"

const suffix = "~>"

/// Encode a BitArray to Adobe Ascii85 with <~ ~> delimiters.
pub fn encode(data: BitArray) -> String {
  prefix
  <> {
    encode_groups(data, [])
    |> list.reverse
    |> string.join("")
  }
  <> suffix
}

fn encode_groups(data: BitArray, acc: List(String)) -> List(String) {
  case data {
    <<0:32, rest:bits>> -> encode_groups(rest, ["z", ..acc])
    <<a:8, b:8, c:8, d:8, rest:bits>> -> {
      let value = a * 16_777_216 + b * 65_536 + c * 256 + d
      let encoded = encode_u32(value, 5, [])
      encode_groups(rest, [chars_to_string(encoded), ..acc])
    }
    <<>> -> acc
    remaining -> {
      let #(padded, original_len) = pad_to_4(remaining, 0)
      case padded {
        <<a:8, b:8, c:8, d:8>> -> {
          let value = a * 16_777_216 + b * 65_536 + c * 256 + d
          let encoded = encode_u32(value, 5, [])
          [chars_to_string(list_take(encoded, original_len + 1)), ..acc]
        }
        _ -> acc
      }
    }
  }
}

fn pad_to_4(data: BitArray, len: Int) -> #(BitArray, Int) {
  use <- bool.guard(when: bit_array.byte_size(data) >= 4, return: #(data, len))
  pad_to_4(bit_array.append(data, <<0:8>>), case len {
    0 -> bit_array.byte_size(data)
    _ -> len
  })
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
      case bit_array.to_string(<<c:int>>) {
        Ok(chunk) -> chunk <> chars_to_string(rest)
        Error(error) -> {
          let _nil_error = error
          chars_to_string(rest)
        }
      }
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

/// Decode an Adobe Ascii85 string (with <~ ~> delimiters) to a BitArray.
pub fn decode(input: String) -> Result(BitArray, CodecError) {
  let trimmed = string.trim(input)
  use <- bool.guard(
    when: !string.starts_with(trimmed, prefix),
    return: Error(InvalidCharacter("<", 0)),
  )
  use <- bool.guard(
    when: !string.ends_with(trimmed, suffix),
    return: Error(InvalidCharacter("~", string.length(trimmed))),
  )
  let inner =
    trimmed
    |> string.drop_start(2)
    |> string.drop_end(2)
  decode_groups(inner, <<>>, 2)
}

fn decode_groups(
  input: String,
  acc: BitArray,
  pos: Int,
) -> Result(BitArray, CodecError) {
  case string.pop_grapheme(input) {
    Error(Nil) -> Ok(acc)
    // Skip whitespace (space, tab, newline, carriage return, form feed)
    Ok(#(" ", rest)) -> decode_groups(rest, acc, pos + 1)
    Ok(#("\t", rest)) -> decode_groups(rest, acc, pos + 1)
    Ok(#("\n", rest)) -> decode_groups(rest, acc, pos + 1)
    Ok(#("\r", rest)) -> decode_groups(rest, acc, pos + 1)
    Ok(#("\u{000C}", rest)) -> decode_groups(rest, acc, pos + 1)
    Ok(#("z", rest)) ->
      decode_groups(rest, bit_array.append(acc, <<0:32>>), pos + 1)
    Ok(#(c1, r1)) ->
      case take_ascii85_group(c1, r1, pos) {
        Error(e) -> Error(e)
        Ok(#(chars, char_count, rest)) -> {
          // Reject 1-char final group (need at least 2 chars)
          case char_count < 2 {
            True -> Error(InvalidLength(pos + char_count))
            False -> {
              let padded = pad_chars(chars, 5)
              case decode_5_chars(padded) {
                Error(e) -> Error(e)
                Ok(n) ->
                  // Overflow check: decoded value must fit in u32
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
}

fn take_ascii85_group(
  first: String,
  input: String,
  pos: Int,
) -> Result(#(List(Int), Int, String), CodecError) {
  case char_to_value(first) {
    Error(Nil) -> Error(InvalidCharacter(first, pos))
    Ok(v) -> collect_group(input, [v], 1, pos + 1)
  }
}

fn collect_group(
  input: String,
  acc: List(Int),
  count: Int,
  pos: Int,
) -> Result(#(List(Int), Int, String), CodecError) {
  use <- bool.guard(
    when: count >= 5,
    return: Ok(#(list.reverse(acc), count, input)),
  )
  case string.pop_grapheme(input) {
    Error(Nil) -> Ok(#(list.reverse(acc), count, ""))
    // Skip whitespace inside groups
    Ok(#(" ", rest)) -> collect_group(rest, acc, count, pos + 1)
    Ok(#("\t", rest)) -> collect_group(rest, acc, count, pos + 1)
    Ok(#("\n", rest)) -> collect_group(rest, acc, count, pos + 1)
    Ok(#("\r", rest)) -> collect_group(rest, acc, count, pos + 1)
    Ok(#("\u{000C}", rest)) -> collect_group(rest, acc, count, pos + 1)
    Ok(#(c, rest)) ->
      case char_to_value(c) {
        Error(Nil) -> Error(InvalidCharacter(c, pos))
        Ok(v) -> collect_group(rest, [v, ..acc], count + 1, pos + 1)
      }
  }
}

fn pad_chars(chars: List(Int), target: Int) -> List(Int) {
  use <- bool.guard(when: list.length(chars) >= target, return: chars)
  pad_chars(list.append(chars, [84]), target)
}

fn decode_5_chars(chars: List(Int)) -> Result(Int, CodecError) {
  case chars {
    [a, b, c, d, e] -> Ok(a * 52_200_625 + b * 614_125 + c * 7225 + d * 85 + e)
    _ -> Error(InvalidLength(list.length(chars)))
  }
}

fn u32_to_bytes(value: Int) -> List(Int) {
  [
    value / 16_777_216 % 256,
    value / 65_536 % 256,
    value / 256 % 256,
    value % 256,
  ]
}

fn char_to_value(c: String) -> Result(Int, Nil) {
  case string.to_utf_codepoints(c) {
    [cp] -> {
      let code = string.utf_codepoint_to_int(cp)
      use <- bool.guard(when: code >= 33 && code <= 117, return: Ok(code - 33))
      Error(Nil)
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
