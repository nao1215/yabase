/// Standard Base64 encoding per RFC 4648.
import gleam/bit_array
import gleam/bool
import gleam/list
import gleam/string
import yabase/core/error.{
  type CodecError, InvalidCharacter, InvalidLength, NonCanonical,
}

const alphabet = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"

const pad = "="

/// Encode a BitArray to standard Base64 with padding.
pub fn encode(data: BitArray) -> String {
  encode_chunks(data, [])
  |> list.reverse
  |> string.join("")
}

fn encode_chunks(data: BitArray, acc: List(String)) -> List(String) {
  case data {
    <<a:6, b:6, c:6, d:6, rest:bits>> -> {
      let chunk = char_at(a) <> char_at(b) <> char_at(c) <> char_at(d)
      encode_chunks(rest, [chunk, ..acc])
    }
    <<a:6, b:6, c:4>> -> [
      char_at(a) <> char_at(b) <> char_at(c * 4) <> pad,
      ..acc
    ]
    <<a:6, b:2>> -> [char_at(a) <> char_at(b * 16) <> pad <> pad, ..acc]
    _ -> acc
  }
}

/// Decode a standard Base64 string to a BitArray.
/// Per RFC 4648 section 3.3, non-alphabet characters (including
/// whitespace, CR/LF, and other punctuation) are rejected. The
/// alphabet check runs before the length check so the caller sees
/// `InvalidCharacter` (with the offending byte and its position)
/// rather than a misleading `InvalidLength` whenever the real fault
/// is an out-of-alphabet byte.
pub fn decode(input: String) -> Result(BitArray, CodecError) {
  case validate_alphabet(input, 0) {
    Error(e) -> Error(e)
    Ok(Nil) -> {
      let len = string.length(input)
      case len % 4 {
        0 -> decode_chars(input, <<>>, 0)
        _ -> Error(InvalidLength(len))
      }
    }
  }
}

/// Decode `input` and additionally reject non-canonical encodings
/// per RFC 4648 §3.5: the trailing pad bits in a 1- or 2-byte final
/// block must be zero. Useful for signature verification and
/// content-addressable storage, where the wire encoding's uniqueness
/// is part of the contract.
///
/// Returns `Error(NonCanonical)` when the input decodes to bytes
/// whose canonical re-encoding differs from the original input.
/// Other failure modes (`InvalidCharacter`, `InvalidLength`) are
/// surfaced unchanged from `decode/1`.
pub fn decode_strict(input: String) -> Result(BitArray, CodecError) {
  case decode(input) {
    Error(e) -> Error(e)
    Ok(bytes) ->
      case encode(bytes) == input {
        True -> Ok(bytes)
        False -> Error(NonCanonical)
      }
  }
}

fn validate_alphabet(input: String, pos: Int) -> Result(Nil, CodecError) {
  case string.pop_grapheme(input) {
    Error(Nil) -> Ok(Nil)
    Ok(#(c, rest)) ->
      case is_alphabet(c) {
        True -> validate_alphabet(rest, pos + 1)
        False -> Error(InvalidCharacter(c, pos))
      }
  }
}

fn is_alphabet(c: String) -> Bool {
  use <- bool.guard(when: c == pad, return: True)
  case value_of(c) {
    Ok(_) -> True
    Error(Nil) -> False
  }
}

fn decode_chars(
  input: String,
  acc: BitArray,
  pos: Int,
) -> Result(BitArray, CodecError) {
  case input {
    "" -> Ok(acc)
    _ -> {
      case take_4(input) {
        Error(Nil) -> Error(InvalidLength(pos))
        Ok(#(c1, c2, c3, c4, rest)) -> {
          case c3 == pad && c4 == pad {
            True ->
              case rest {
                "" ->
                  case value_of(c1), value_of(c2) {
                    Ok(v1), Ok(v2) -> {
                      let byte = v1 * 4 + v2 / 16
                      Ok(bit_array.append(acc, <<byte:int>>))
                    }
                    Error(Nil), _ -> Error(InvalidCharacter(c1, pos))
                    _, Error(Nil) -> Error(InvalidCharacter(c2, pos + 1))
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
                        Error(Nil), _, _ -> Error(InvalidCharacter(c1, pos))
                        _, Error(Nil), _ -> Error(InvalidCharacter(c2, pos + 1))
                        _, _, Error(Nil) -> Error(InvalidCharacter(c3, pos + 2))
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
                    Error(Nil), _, _, _ -> Error(InvalidCharacter(c1, pos))
                    _, Error(Nil), _, _ -> Error(InvalidCharacter(c2, pos + 1))
                    _, _, Error(Nil), _ -> Error(InvalidCharacter(c3, pos + 2))
                    _, _, _, Error(Nil) -> Error(InvalidCharacter(c4, pos + 3))
                  }
              }
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
    Error(error) -> {
      let _nil_error = error
      ""
    }
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
    "+" -> Ok(62)
    "/" -> Ok(63)
    _ -> Error(Nil)
  }
}
