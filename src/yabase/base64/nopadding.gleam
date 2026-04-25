/// Base64 encoding without padding.
/// Same as standard Base64 but padding characters are stripped.
import gleam/string
import yabase/base64/standard
import yabase/core/encoding.{type CodecError, InvalidCharacter, InvalidLength}

const alphabet = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"

/// Encode a BitArray to Base64 without padding.
pub fn encode(data: BitArray) -> String {
  standard.encode(data)
  |> string.replace("=", "")
}

/// Decode a Base64 string (without padding) to a BitArray.
/// Length % 4 must be 0, 2, or 3 (never 1).
/// Padding characters (=) and any non-alphabet byte (whitespace,
/// CR/LF, punctuation) are rejected with `InvalidCharacter` carrying
/// the offending byte and its position. The alphabet check runs
/// before the length check so a whitespace byte does not surface as
/// a misleading `InvalidLength`.
pub fn decode(input: String) -> Result(BitArray, CodecError) {
  case validate_alphabet(input, 0) {
    Error(e) -> Error(e)
    Ok(Nil) -> {
      let len = string.length(input)
      case len % 4 {
        1 -> Error(InvalidLength(len))
        _ -> {
          let padded = add_padding(input)
          standard.decode(padded)
        }
      }
    }
  }
}

fn validate_alphabet(input: String, pos: Int) -> Result(Nil, CodecError) {
  case string.pop_grapheme(input) {
    Error(Nil) -> Ok(Nil)
    Ok(#(c, rest)) ->
      case string.contains(alphabet, c) {
        True -> validate_alphabet(rest, pos + 1)
        False -> Error(InvalidCharacter(c, pos))
      }
  }
}

fn add_padding(input: String) -> String {
  let remainder = string.length(input) % 4
  case remainder {
    2 -> input <> "=="
    3 -> input <> "="
    _ -> input
  }
}
