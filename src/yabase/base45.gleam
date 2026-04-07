/// Base45 encoding per RFC 9285.
/// Alphabet: 0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ $%*+-./:
import gleam/bit_array
import gleam/string
import yabase/core/encoding.{
  type CodecError, InvalidCharacter, InvalidLength, Overflow,
}

const alphabet = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ $%*+-./:"

/// Encode a BitArray to Base45.
pub fn encode(data: BitArray) -> String {
  encode_pairs(data, [])
  |> list_reverse
  |> string.join("")
}

fn encode_pairs(data: BitArray, acc: List(String)) -> List(String) {
  case data {
    <<a:8, b:8, rest:bits>> -> {
      let n = a * 256 + b
      let c = n % 45
      let d = { n / 45 } % 45
      let e = n / 45 / 45
      encode_pairs(rest, [
        string_char_at(alphabet, e),
        string_char_at(alphabet, d),
        string_char_at(alphabet, c),
        ..acc
      ])
    }
    <<a:8>> -> {
      let c = a % 45
      let d = a / 45
      [string_char_at(alphabet, d), string_char_at(alphabet, c), ..acc]
    }
    _ -> acc
  }
}

/// Decode a Base45 string to a BitArray.
pub fn decode(input: String) -> Result(BitArray, CodecError) {
  let len = string.length(input)
  case len % 3 {
    1 -> Error(InvalidLength(len))
    _ -> decode_groups(input, <<>>, 0)
  }
}

fn decode_groups(
  input: String,
  acc: BitArray,
  pos: Int,
) -> Result(BitArray, CodecError) {
  case take_chars(input, 3) {
    #(Error(Nil), _) -> Ok(acc)
    #(Ok([c, d, e]), rest) ->
      case char_value(c), char_value(d), char_value(e) {
        Ok(vc), Ok(vd), Ok(ve) -> {
          let n = vc + vd * 45 + ve * 45 * 45
          case n > 65_535 {
            True -> Error(Overflow)
            False -> {
              let high = n / 256
              let low = n % 256
              decode_groups(
                rest,
                bit_array.append(acc, <<high:int, low:int>>),
                pos + 3,
              )
            }
          }
        }
        Error(_), _, _ -> Error(InvalidCharacter(c, pos))
        _, Error(_), _ -> Error(InvalidCharacter(d, pos + 1))
        _, _, Error(_) -> Error(InvalidCharacter(e, pos + 2))
      }
    #(Ok([c, d]), _rest) ->
      case char_value(c), char_value(d) {
        Ok(vc), Ok(vd) -> {
          let n = vc + vd * 45
          case n > 255 {
            True -> Error(Overflow)
            False -> Ok(bit_array.append(acc, <<n:int>>))
          }
        }
        Error(_), _ -> Error(InvalidCharacter(c, pos))
        _, Error(_) -> Error(InvalidCharacter(d, pos + 1))
      }
    _ -> Ok(acc)
  }
}

fn take_chars(input: String, n: Int) -> #(Result(List(String), Nil), String) {
  take_chars_acc(input, n, [])
}

fn take_chars_acc(
  input: String,
  n: Int,
  acc: List(String),
) -> #(Result(List(String), Nil), String) {
  case n {
    0 -> #(Ok(list_reverse(acc)), input)
    _ ->
      case string.pop_grapheme(input) {
        Error(Nil) ->
          case acc {
            [] -> #(Error(Nil), "")
            _ -> #(Ok(list_reverse(acc)), "")
          }
        Ok(#(c, rest)) -> take_chars_acc(rest, n - 1, [c, ..acc])
      }
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
