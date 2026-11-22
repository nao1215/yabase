/// Z85 encoding (ZeroMQ variant of Ascii85).
/// Alphabet: 0-9, a-z, A-Z, ., -, :, +, =, ^, !, /, *, ?, &, <, >, (, ), [, ], {, }, @, %, $, #
/// Input length for encode MUST be a multiple of 4.
import gleam/bit_array
import gleam/bool
import yabase/core/error.{type CodecError, InvalidLength}
import yabase/internal/alphabet
import yabase/internal/base85

const symbols =
  "0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ.-:+=^!/*?&<>()[]{}@%$#"

/// Encode a BitArray to Z85.
/// Returns Error(InvalidLength(byte length)) if the input length is not a
/// multiple of 4, and Error(InvalidLength(bit size)) if it is not a whole
/// number of bytes.
pub fn encode(data: BitArray) -> Result(String, CodecError) {
  let bits = bit_array.bit_size(data)
  use <- bool.guard(when: bits % 8 != 0, return: Error(InvalidLength(bits)))
  let length = bit_array.byte_size(data)
  use <- bool.guard(when: length % 4 != 0, return: Error(InvalidLength(length)))
  Ok(base85.encode(
    data,
    alphabet.new(symbols, alphabet.CaseSensitive),
    base85.NoShortcuts,
  ))
}

/// Decode a Z85 string to a BitArray.
/// Input length must be a multiple of 5.
pub fn decode(input: String) -> Result(BitArray, CodecError) {
  base85.decode_groups(input, alphabet.new(symbols, alphabet.CaseSensitive))
}
