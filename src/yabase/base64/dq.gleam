/// Base64 DQ encoding (Dragon Quest revival password style).
/// Uses Japanese hiragana as the 64-symbol alphabet.
/// Padding character: ・ (middle dot).
import gleam/bit_array
import gleam/bool
import gleam/list
import gleam/string
import yabase/core/error.{type CodecError, InvalidCharacter, InvalidLength}

const dq_alphabet = [
  "あ", "い", "う", "え", "お", "か", "き", "く", "け", "こ", "さ", "し", "す", "せ", "そ", "た",
  "ち", "つ", "て", "と", "な", "に", "ぬ", "ね", "の", "は", "ひ", "ふ", "へ", "ほ", "ま", "み",
  "む", "め", "も", "や", "ゆ", "よ", "ら", "り", "る", "れ", "ろ", "わ", "が", "ぎ", "ぐ", "げ",
  "ご", "ざ", "じ", "ず", "ぜ", "ぞ", "だ", "ぢ", "づ", "で", "ど", "ば", "び", "ぶ", "べ", "ぼ",
]

const dq_pad = "・"

/// Encode a BitArray to Base64 DQ (hiragana).
pub fn encode(data: BitArray) -> String {
  encode_chunks(data, [])
  |> list.reverse
  |> string.join("")
}

fn encode_chunks(data: BitArray, acc: List(String)) -> List(String) {
  case data {
    <<a:6, b:6, c:6, d:6, rest:bits>> ->
      encode_chunks(rest, [
        dq_char_at(d),
        dq_char_at(c),
        dq_char_at(b),
        dq_char_at(a),
        ..acc
      ])
    <<a:6, b:6, c:4>> -> [
      dq_pad,
      dq_char_at(c * 4),
      dq_char_at(b),
      dq_char_at(a),
      ..acc
    ]
    <<a:6, b:2>> -> [dq_pad, dq_pad, dq_char_at(b * 16), dq_char_at(a), ..acc]
    _ -> acc
  }
}

/// Decode a Base64 DQ (hiragana) string to a BitArray.
///
/// Non-alphabet graphemes (whitespace, ASCII, mismatched kana, etc.)
/// are rejected with `InvalidCharacter` carrying the offending
/// grapheme and its position. The alphabet check runs before the
/// length check so the caller does not see a misleading
/// `InvalidLength` when the real fault is an out-of-alphabet
/// grapheme.
pub fn decode(input: String) -> Result(BitArray, CodecError) {
  let graphemes = string.to_graphemes(input)
  case validate_alphabet(graphemes, 0) {
    Error(e) -> Error(e)
    Ok(Nil) -> {
      let len = list.length(graphemes)
      case len % 4 {
        0 -> decode_graphemes(graphemes, <<>>, 0)
        _ -> Error(InvalidLength(len))
      }
    }
  }
}

fn validate_alphabet(
  graphemes: List(String),
  pos: Int,
) -> Result(Nil, CodecError) {
  case graphemes {
    [] -> Ok(Nil)
    [c, ..rest] ->
      case is_alphabet(c) {
        True -> validate_alphabet(rest, pos + 1)
        False -> Error(InvalidCharacter(c, pos))
      }
  }
}

fn is_alphabet(c: String) -> Bool {
  use <- bool.guard(when: c == dq_pad, return: True)
  case dq_value_of(c) {
    Ok(_) -> True
    Error(Nil) -> False
  }
}

fn decode_graphemes(
  chars: List(String),
  acc: BitArray,
  pos: Int,
) -> Result(BitArray, CodecError) {
  case chars {
    [] -> Ok(acc)
    [c1, c2, c3, c4, ..rest] ->
      case c3 == dq_pad && c4 == dq_pad {
        True ->
          case rest {
            [] ->
              case dq_value_of(c1), dq_value_of(c2) {
                Ok(v1), Ok(v2) ->
                  Ok(bit_array.append(acc, <<{ v1 * 4 + v2 / 16 }:int>>))
                Error(_), _ -> Error(InvalidCharacter(c1, pos))
                _, Error(_) -> Error(InvalidCharacter(c2, pos + 1))
              }
            _ -> Error(InvalidLength(list.length(rest) + pos + 4))
          }
        False ->
          case c4 == dq_pad {
            True ->
              case rest {
                [] ->
                  case dq_value_of(c1), dq_value_of(c2), dq_value_of(c3) {
                    Ok(v1), Ok(v2), Ok(v3) -> {
                      let b1 = v1 * 4 + v2 / 16
                      let b2 = { v2 % 16 } * 16 + v3 / 4
                      Ok(bit_array.append(acc, <<b1:int, b2:int>>))
                    }
                    Error(_), _, _ -> Error(InvalidCharacter(c1, pos))
                    _, Error(_), _ -> Error(InvalidCharacter(c2, pos + 1))
                    _, _, Error(_) -> Error(InvalidCharacter(c3, pos + 2))
                  }
                _ -> Error(InvalidLength(list.length(rest) + pos + 4))
              }
            False ->
              case
                dq_value_of(c1),
                dq_value_of(c2),
                dq_value_of(c3),
                dq_value_of(c4)
              {
                Ok(v1), Ok(v2), Ok(v3), Ok(v4) -> {
                  let b1 = v1 * 4 + v2 / 16
                  let b2 = { v2 % 16 } * 16 + v3 / 4
                  let b3 = { v3 % 4 } * 64 + v4
                  decode_graphemes(
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
    remaining -> Error(InvalidLength(pos + list.length(remaining)))
  }
}

fn dq_char_at(index: Int) -> String {
  case list.drop(dq_alphabet, index) {
    [c, ..] -> c
    [] -> ""
  }
}

fn dq_value_of(c: String) -> Result(Int, Nil) {
  find_index(dq_alphabet, c, 0)
}

fn find_index(
  haystack: List(String),
  needle: String,
  idx: Int,
) -> Result(Int, Nil) {
  case haystack {
    [] -> Error(Nil)
    [h, ..rest] ->
      case h == needle {
        True -> Ok(idx)
        False -> find_index(rest, needle, idx + 1)
      }
  }
}
