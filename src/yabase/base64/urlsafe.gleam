/// URL-safe Base64 encoding (RFC 4648 section 5).
/// Uses - instead of + and _ instead of /.
import gleam/bit_array
import gleam/string
import yabase/core/encoding.{type CodecError, InvalidCharacter, InvalidLength}

const alphabet = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-_"

const pad = "="

/// Encode a BitArray to URL-safe Base64 with padding.
pub fn encode(data: BitArray) -> String {
  encode_chunks(data, [])
  |> list_reverse
  |> string.join("")
}

fn encode_chunks(data: BitArray, acc: List(String)) -> List(String) {
  case data {
    <<a:6, b:6, c:6, d:6, rest:bits>> ->
      encode_chunks(rest, [
        char_at(d),
        char_at(c),
        char_at(b),
        char_at(a),
        ..acc
      ])
    <<a:6, b:6, c:4>> -> [pad, char_at(c * 4), char_at(b), char_at(a), ..acc]
    <<a:6, b:2>> -> [pad, pad, char_at(b * 16), char_at(a), ..acc]
    _ -> acc
  }
}

/// Decode a URL-safe Base64 string to a BitArray.
/// Per RFC 4648 section 3.3, non-alphabet characters (including CR/LF)
/// are rejected.
pub fn decode(input: String) -> Result(BitArray, CodecError) {
  let len = string.length(input)
  case len % 4 {
    0 -> decode_chars(input, <<>>, 0)
    _ -> Error(InvalidLength(len))
  }
}

fn decode_chars(
  input: String,
  acc: BitArray,
  pos: Int,
) -> Result(BitArray, CodecError) {
  case input {
    "" -> Ok(acc)
    _ ->
      case take_4(input) {
        Error(Nil) -> Error(InvalidLength(pos))
        Ok(#(c1, c2, c3, c4, rest)) ->
          case c3 == pad && c4 == pad {
            True ->
              case rest {
                "" ->
                  case value_of(c1), value_of(c2) {
                    Ok(v1), Ok(v2) ->
                      Ok(bit_array.append(acc, <<{ v1 * 4 + v2 / 16 }:int>>))
                    Error(_), _ -> Error(InvalidCharacter(c1, pos))
                    _, Error(_) -> Error(InvalidCharacter(c2, pos + 1))
                  }
                _ -> Error(InvalidLength(string.length(rest) + pos + 4))
              }
            False ->
              case c4 == pad {
                True ->
                  case rest {
                    "" ->
                      case value_of(c1), value_of(c2), value_of(c3) {
                        Ok(v1), Ok(v2), Ok(v3) -> {
                          let b1 = v1 * 4 + v2 / 16
                          let b2 = { v2 % 16 } * 16 + v3 / 4
                          Ok(bit_array.append(acc, <<b1:int, b2:int>>))
                        }
                        Error(_), _, _ -> Error(InvalidCharacter(c1, pos))
                        _, Error(_), _ -> Error(InvalidCharacter(c2, pos + 1))
                        _, _, Error(_) -> Error(InvalidCharacter(c3, pos + 2))
                      }
                    _ -> Error(InvalidLength(string.length(rest) + pos + 4))
                  }
                False ->
                  case value_of(c1), value_of(c2), value_of(c3), value_of(c4) {
                    Ok(v1), Ok(v2), Ok(v3), Ok(v4) -> {
                      let b1 = v1 * 4 + v2 / 16
                      let b2 = { v2 % 16 } * 16 + v3 / 4
                      let b3 = { v3 % 4 } * 64 + v4
                      decode_chars(
                        rest,
                        bit_array.append(acc, <<b1:int, b2:int, b3:int>>),
                        pos + 4,
                      )
                    }
                    Error(_), _, _, _ -> Error(InvalidCharacter(c1, pos))
                    _, Error(_), _, _ -> Error(InvalidCharacter(c2, pos + 1))
                    _, _, Error(_), _ -> Error(InvalidCharacter(c3, pos + 2))
                    _, _, _, Error(_) -> Error(InvalidCharacter(c4, pos + 3))
                  }
              }
          }
      }
  }
}

fn take_4(
  input: String,
) -> Result(#(String, String, String, String, String), Nil) {
  case string.pop_grapheme(input) {
    Error(Nil) -> Error(Nil)
    Ok(#(c1, r1)) ->
      case string.pop_grapheme(r1) {
        Error(Nil) -> Error(Nil)
        Ok(#(c2, r2)) ->
          case string.pop_grapheme(r2) {
            Error(Nil) -> Error(Nil)
            Ok(#(c3, r3)) ->
              case string.pop_grapheme(r3) {
                Error(Nil) -> Error(Nil)
                Ok(#(c4, r4)) -> Ok(#(c1, c2, c3, c4, r4))
              }
          }
      }
  }
}

fn char_at(index: Int) -> String {
  case string.drop_start(alphabet, index) |> string.pop_grapheme {
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

fn value_of(c: String) -> Result(Int, Nil) {
  case c {
    "A" -> Ok(0)
    "B" -> Ok(1)
    "C" -> Ok(2)
    "D" -> Ok(3)
    "E" -> Ok(4)
    "F" -> Ok(5)
    "G" -> Ok(6)
    "H" -> Ok(7)
    "I" -> Ok(8)
    "J" -> Ok(9)
    "K" -> Ok(10)
    "L" -> Ok(11)
    "M" -> Ok(12)
    "N" -> Ok(13)
    "O" -> Ok(14)
    "P" -> Ok(15)
    "Q" -> Ok(16)
    "R" -> Ok(17)
    "S" -> Ok(18)
    "T" -> Ok(19)
    "U" -> Ok(20)
    "V" -> Ok(21)
    "W" -> Ok(22)
    "X" -> Ok(23)
    "Y" -> Ok(24)
    "Z" -> Ok(25)
    "a" -> Ok(26)
    "b" -> Ok(27)
    "c" -> Ok(28)
    "d" -> Ok(29)
    "e" -> Ok(30)
    "f" -> Ok(31)
    "g" -> Ok(32)
    "h" -> Ok(33)
    "i" -> Ok(34)
    "j" -> Ok(35)
    "k" -> Ok(36)
    "l" -> Ok(37)
    "m" -> Ok(38)
    "n" -> Ok(39)
    "o" -> Ok(40)
    "p" -> Ok(41)
    "q" -> Ok(42)
    "r" -> Ok(43)
    "s" -> Ok(44)
    "t" -> Ok(45)
    "u" -> Ok(46)
    "v" -> Ok(47)
    "w" -> Ok(48)
    "x" -> Ok(49)
    "y" -> Ok(50)
    "z" -> Ok(51)
    "0" -> Ok(52)
    "1" -> Ok(53)
    "2" -> Ok(54)
    "3" -> Ok(55)
    "4" -> Ok(56)
    "5" -> Ok(57)
    "6" -> Ok(58)
    "7" -> Ok(59)
    "8" -> Ok(60)
    "9" -> Ok(61)
    "-" -> Ok(62)
    "_" -> Ok(63)
    _ -> Error(Nil)
  }
}
