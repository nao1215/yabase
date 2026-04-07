/// Base58 encoding (Flickr alphabet).
/// Alphabet: 123456789abcdefghijkmnopqrstuvwxyzABCDEFGHJKLMNPQRSTUVWXYZ
/// Same as Bitcoin but with swapped upper/lower case.
import yabase/core/encoding.{type CodecError}
import yabase/internal/bignum

const alphabet = "123456789abcdefghijkmnopqrstuvwxyzABCDEFGHJKLMNPQRSTUVWXYZ"

/// Encode a BitArray to Base58 (Flickr).
pub fn encode(data: BitArray) -> String {
  bignum.encode(data, 58, alphabet)
}

/// Decode a Base58 string (Flickr alphabet) to a BitArray.
pub fn decode(input: String) -> Result(BitArray, CodecError) {
  bignum.decode(input, 58, "1", char_value)
}

fn char_value(c: String) -> Result(Int, Nil) {
  bignum.find_index(alphabet, c, 0)
}
