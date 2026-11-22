/// RFC 1924 Base85 encoding.
/// Uses a specific 85-character alphabet designed for IPv6 addresses.
/// Encodes 16 bytes (128 bits) into 20 characters.
/// Can also encode arbitrary data in 4-byte groups like Z85.
import gleam/bit_array
import gleam/bool
import yabase/core/error.{type CodecError, InvalidLength}
import yabase/internal/alphabet
import yabase/internal/base85

const symbols =
  "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz!#$%&()*+-;<=>?@^_`{|}~"

/// Encode a BitArray to RFC 1924 Base85.
/// Input length must be a multiple of 4 bytes; otherwise the result is
/// Error(InvalidLength(byte length)), or Error(InvalidLength(bit size))
/// when the input is not a whole number of bytes.
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

/// Decode an RFC 1924 Base85 string to a BitArray.
/// Input length must be a multiple of 5 characters.
pub fn decode(input: String) -> Result(BitArray, CodecError) {
  base85.decode_groups(input, alphabet.new(symbols, alphabet.CaseSensitive))
}
