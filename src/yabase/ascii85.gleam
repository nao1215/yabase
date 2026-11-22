/// Ascii85 (btoa) encoding.
/// Encodes 4-byte groups into 5 ASCII characters from '!' (33) to 'u' (117).
/// Special case: all-zero groups encode as 'z'.
/// Special case: all-space groups (0x20202020) encode as 'y'.
import yabase/core/error.{type CodecError}
import yabase/core/guard
import yabase/internal/base85

/// Encode a BitArray to Ascii85.
///
/// Sub-byte input panics; see
/// `yabase/core/guard.assert_byte_aligned`.
pub fn encode(data: BitArray) -> String {
  guard.assert_byte_aligned(data)
  base85.encode(data, base85.ascii85_alphabet(), base85.ZeroAndSpaceShortcuts)
}

/// Decode an Ascii85 string to a BitArray.
pub fn decode(input: String) -> Result(BitArray, CodecError) {
  base85.decode_ascii85(input, base85.ZeroAndSpaceShortcuts, 0)
}
