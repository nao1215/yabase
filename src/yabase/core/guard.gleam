//// Shared encode-side preconditions.

import gleam/bit_array
import gleam/int

/// Reject a `BitArray` whose total bit length is not a multiple of 8.
///
/// yabase encoders walk their input one byte at a time. A sub-byte
/// trailing segment (`<<1:size(1)>>`, `<<0xFF, 0x80, 1:size(3)>>`,
/// …) would otherwise be silently dropped by the byte-walker
/// pattern, producing a string that decodes to a strictly shorter
/// `BitArray` than the caller supplied — silent data loss. Every
/// `encode` function calls this at the boundary so the truncation
/// becomes a loud crash instead.
///
/// Crashing rather than returning a `Result` keeps the public
/// `encode` shape per-codec compatible with v0.14.x callers
/// (`fn(BitArray) -> String`); a sub-byte input has always been
/// outside the contract, so there is no caller that previously
/// "worked" with one. RFC 4648-conformant encoders never receive
/// sub-byte input in practice, so the guard is a safety net for
/// programmer-error inputs only.
pub fn assert_byte_aligned(input: BitArray) -> Nil {
  let bits = bit_array.bit_size(input)
  case bits % 8 == 0 {
    True -> Nil
    False ->
      panic as {
        "yabase encode: input must be byte-aligned (a multiple of "
        <> "8 bits); got "
        <> int.to_string(bits)
        <> " bits"
      }
  }
}
