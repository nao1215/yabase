/// Clockwork Base32 encoding.
/// Human-friendly variant: no padding, no confusable characters.
/// Alphabet: 0123456789ABCDEFGHJKMNPQRSTVWXYZ
/// Decoding: o/O->0, i/I/l/L->1
import yabase/core/error.{type CodecError}
import yabase/core/guard
import yabase/internal/alphabet
import yabase/internal/bitgroup

fn clockwork() -> alphabet.Alphabet {
  alphabet.with_extras(
    symbols: "0123456789ABCDEFGHJKMNPQRSTVWXYZ",
    folding: alphabet.FoldToUpper,
    aliases: [#("O", 0), #("I", 1), #("L", 1)],
    ignore: "",
  )
}

/// Encode a BitArray to Clockwork Base32 (no padding).
///
/// Sub-byte input panics; see
/// `yabase/core/guard.assert_byte_aligned`.
pub fn encode(data: BitArray) -> String {
  guard.assert_byte_aligned(data)
  bitgroup.encode(data, 5, clockwork(), bitgroup.Unpadded)
}

/// Decode a Clockwork Base32 string to a BitArray.
/// Case-insensitive. o/O->0, i/I/l/L->1.
///
/// Non-alphabet characters (whitespace, CR/LF, punctuation outside
/// Clockwork's accepted set) are rejected with `InvalidCharacter`
/// carrying the offending byte and its position. The alphabet
/// check runs before the length check so the caller does not see
/// a misleading `InvalidLength` when the real fault is an
/// out-of-alphabet byte.
pub fn decode(input: String) -> Result(BitArray, CodecError) {
  bitgroup.decode_unpadded(input, 5, clockwork())
}
