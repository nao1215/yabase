/// URL-safe Base64 encoding without padding.
/// Same as URL-safe Base64 but padding characters are stripped.
import gleam/string
import yabase/base64/urlsafe
import yabase/core/error.{type CodecError, InvalidCharacter, InvalidLength}

/// Encode a BitArray to URL-safe Base64 without padding.
pub fn encode(data: BitArray) -> String {
  urlsafe.encode(data)
  |> string.replace("=", "")
}

/// Decode a URL-safe Base64 string without padding to a BitArray.
/// Length % 4 must be 0, 2, or 3 (never 1).
/// Padding characters (=) are rejected.
pub fn decode(input: String) -> Result(BitArray, CodecError) {
  // Scan for the first invalid character (including "=") and report it
  case find_first_invalid(input, 0) {
    Ok(#(c, pos)) -> Error(InvalidCharacter(c, pos))
    Error(Nil) -> {
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

fn find_first_invalid(input: String, pos: Int) -> Result(#(String, Int), Nil) {
  case string.pop_grapheme(input) {
    Error(Nil) -> Error(Nil)
    Ok(#(c, rest)) ->
      case is_urlsafe_base64_char(c) {
        True -> find_first_invalid(rest, pos + 1)
        False -> Ok(#(c, pos))
      }
  }
}

fn is_urlsafe_base64_char(c: String) -> Bool {
  case c {
    "A"
    | "B"
    | "C"
    | "D"
    | "E"
    | "F"
    | "G"
    | "H"
    | "I"
    | "J"
    | "K"
    | "L"
    | "M"
    | "N"
    | "O"
    | "P"
    | "Q"
    | "R"
    | "S"
    | "T"
    | "U"
    | "V"
    | "W"
    | "X"
    | "Y"
    | "Z" -> True
    "a"
    | "b"
    | "c"
    | "d"
    | "e"
    | "f"
    | "g"
    | "h"
    | "i"
    | "j"
    | "k"
    | "l"
    | "m"
    | "n"
    | "o"
    | "p"
    | "q"
    | "r"
    | "s"
    | "t"
    | "u"
    | "v"
    | "w"
    | "x"
    | "y"
    | "z" -> True
    "0" | "1" | "2" | "3" | "4" | "5" | "6" | "7" | "8" | "9" -> True
    "-" | "_" -> True
    _ -> False
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
