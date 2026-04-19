/// Base58Check encoding (Bitcoin).
/// Format: version_byte(1) + payload(N) + checksum(4)
/// Checksum = first 4 bytes of SHA-256(SHA-256(version + payload)).
/// This is a separate API from the Encoding ADT because it carries metadata.
import gleam/bit_array
import gleam/bool
import gleam/string
import yabase/core/encoding.{
  type Base58CheckDecoded, type CodecError, Base58CheckDecoded, InvalidChecksum,
  InvalidLength, Overflow,
}
import yabase/internal/bignum
import yabase/internal/sha256

const alphabet = "123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz"

/// Encode a version byte (0..255) and payload to Base58Check.
/// Returns Error(Overflow) if version is outside 0..255.
pub fn encode(version: Int, payload: BitArray) -> Result(String, CodecError) {
  use <- bool.guard(when: version < 0 || version > 255, return: Error(Overflow))
  let versioned = bit_array.append(<<version:int>>, payload)
  let checksum = compute_checksum(versioned)
  let full = bit_array.append(versioned, checksum)
  Ok(bignum.encode(full, 58, alphabet))
}

/// Decode a Base58Check string, verifying the checksum.
/// Returns the version byte and payload on success.
pub fn decode(input: String) -> Result(Base58CheckDecoded, CodecError) {
  case bignum.decode(input, 58, "1", char_value) {
    Error(e) -> Error(e)
    Ok(bytes) -> {
      let len = bit_array.byte_size(bytes)
      case len < 5 {
        True -> Error(InvalidLength(len))
        False -> {
          let payload_len = len - 5
          case bytes {
            <<
              version:8,
              payload:bytes-size(payload_len),
              checksum:bytes-size(4),
            >> -> {
              let versioned = bit_array.append(<<version:int>>, payload)
              let expected = compute_checksum(versioned)
              case checksum == expected {
                True ->
                  Ok(Base58CheckDecoded(version: version, payload: payload))
                False -> Error(InvalidChecksum)
              }
            }
            _ -> Error(InvalidLength(len))
          }
        }
      }
    }
  }
}

fn compute_checksum(data: BitArray) -> BitArray {
  let hash1 = sha256.hash(data)
  let hash2 = sha256.hash(hash1)
  case hash2 {
    <<a:8, b:8, c:8, d:8, _:bits>> -> <<a:int, b:int, c:int, d:int>>
    _ -> <<0, 0, 0, 0>>
  }
}

fn char_value(c: String) -> Result(Int, Nil) {
  find_index(alphabet, c, 0)
}

fn find_index(haystack: String, needle: String, idx: Int) -> Result(Int, Nil) {
  case string.pop_grapheme(haystack) {
    Error(Nil) -> Error(Nil)
    Ok(#(ch, rest)) ->
      case ch == needle {
        True -> Ok(idx)
        False -> find_index(rest, needle, idx + 1)
      }
  }
}
