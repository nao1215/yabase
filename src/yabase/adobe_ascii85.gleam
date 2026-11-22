/// Adobe Ascii85 encoding (used in PDF/PostScript).
/// Uses <~ ~> delimiters and does not support btoa's 'y' space shortcut.
/// All-zero 4-byte groups encode as 'z'.
import gleam/bool
import gleam/string
import yabase/core/error.{type CodecError, InvalidCharacter}
import yabase/core/guard
import yabase/internal/base85

const prefix = "<~"

const suffix = "~>"

/// Encode a BitArray to Adobe Ascii85 with <~ ~> delimiters.
///
/// Sub-byte input panics; see
/// `yabase/core/guard.assert_byte_aligned`.
pub fn encode(data: BitArray) -> String {
  guard.assert_byte_aligned(data)
  prefix
  <> base85.encode(data, base85.ascii85_alphabet(), base85.ZeroShortcut)
  <> suffix
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
  base85.decode_ascii85(inner, base85.ZeroShortcut, 2)
}
