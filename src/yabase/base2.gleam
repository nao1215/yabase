/// Base2 encoding (binary string representation).
/// Each byte is represented as 8 characters of "0" and "1".
import yabase/core/error.{type CodecError}
import yabase/core/guard
import yabase/internal/alphabet
import yabase/internal/bitgroup

fn binary() -> alphabet.Alphabet {
  alphabet.new("01", alphabet.CaseSensitive)
}

/// Encode a BitArray to a binary string (e.g. <<0x41>> -> "01000001").
///
/// Sub-byte input (a `BitArray` whose bit size is not a multiple of
/// 8) panics; the byte-walker would otherwise silently drop the
/// trailing fewer-than-8-bit segment. See
/// `yabase/core/guard.assert_byte_aligned`.
pub fn encode(data: BitArray) -> String {
  guard.assert_byte_aligned(data)
  bitgroup.encode(data, 1, binary(), bitgroup.Unpadded)
}

/// Decode a binary string to a BitArray.
/// Input length must be a multiple of 8. Only "0" and "1" are valid.
pub fn decode(input: String) -> Result(BitArray, CodecError) {
  bitgroup.decode_exact(input, 1, binary())
}
