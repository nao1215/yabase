/// Base64 encoding without padding.
/// Same as standard Base64 but padding characters are stripped.
import gleam/string
import yabase/base64/standard
import yabase/core/encoding.{type CodecError, InvalidLength}

/// Encode a BitArray to Base64 without padding.
pub fn encode(data: BitArray) -> String {
  standard.encode(data)
  |> string.replace("=", "")
}

/// Decode a Base64 string (without padding) to a BitArray.
/// Length % 4 must be 0, 2, or 3 (never 1).
pub fn decode(input: String) -> Result(BitArray, CodecError) {
  let len = string.length(input)
  case len % 4 {
    1 -> Error(InvalidLength(len))
    _ -> {
      let padded = add_padding(input)
      standard.decode(padded)
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
