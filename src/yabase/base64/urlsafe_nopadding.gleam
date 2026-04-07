/// URL-safe Base64 encoding without padding.
/// Same as URL-safe Base64 but padding characters are stripped.
import gleam/string
import yabase/base64/urlsafe
import yabase/core/encoding.{type CodecError, InvalidCharacter, InvalidLength}

/// Encode a BitArray to URL-safe Base64 without padding.
pub fn encode(data: BitArray) -> String {
  urlsafe.encode(data)
  |> string.replace("=", "")
}

/// Decode a URL-safe Base64 string without padding to a BitArray.
/// Length % 4 must be 0, 2, or 3 (never 1).
/// Padding characters (=) are rejected.
pub fn decode(input: String) -> Result(BitArray, CodecError) {
  case string.contains(input, "=") {
    True -> Error(InvalidCharacter("=", find_char_pos(input, "=", 0)))
    False -> {
      let len = string.length(input)
      case len % 4 {
        1 -> Error(InvalidLength(len))
        _ -> {
          let padded = add_padding(input)
          urlsafe.decode(padded)
        }
      }
    }
  }
}

fn find_char_pos(input: String, target: String, pos: Int) -> Int {
  case string.pop_grapheme(input) {
    Error(Nil) -> pos
    Ok(#(c, rest)) ->
      case c == target {
        True -> pos
        False -> find_char_pos(rest, target, pos + 1)
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
