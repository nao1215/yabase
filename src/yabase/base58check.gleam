/// Base58Check encoding (Bitcoin).
/// Format: version_byte(1) + payload(N) + checksum(4)
/// Checksum = first 4 bytes of SHA-256(SHA-256(version + payload)).
/// This is a separate API from the Encoding ADT because it carries metadata.
import gleam/bit_array
import gleam/list
import gleam/string
import yabase/core/encoding.{
  type Base58CheckDecoded, type CodecError, Base58CheckDecoded, InvalidCharacter,
  InvalidChecksum, InvalidLength, Overflow,
}
import yabase/internal/sha256

const alphabet = "123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz"

/// Encode a version byte (0..255) and payload to Base58Check.
/// Returns Error(Overflow) if version is outside 0..255.
pub fn encode(version: Int, payload: BitArray) -> Result(String, CodecError) {
  case version >= 0 && version <= 255 {
    False -> Error(Overflow)
    True -> {
      let versioned = bit_array.append(<<version:int>>, payload)
      let checksum = compute_checksum(versioned)
      let full = bit_array.append(versioned, checksum)
      Ok(encode_base58(full))
    }
  }
}

/// Decode a Base58Check string, verifying the checksum.
/// Returns the version byte and payload on success.
pub fn decode(input: String) -> Result(Base58CheckDecoded, CodecError) {
  case decode_base58(input) {
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

// Base58 encode/decode (same as yabase/base58 but self-contained to avoid circular deps)

fn encode_base58(data: BitArray) -> String {
  let leading_zeros = count_leading_zeros(data, 0)
  let num = bytes_to_int(data, 0)
  let encoded = encode_int(num, "")
  string.repeat("1", leading_zeros) <> encoded
}

fn count_leading_zeros(data: BitArray, count: Int) -> Int {
  case data {
    <<0:8, rest:bits>> -> count_leading_zeros(rest, count + 1)
    _ -> count
  }
}

fn bytes_to_int(data: BitArray, acc: Int) -> Int {
  case data {
    <<byte:8, rest:bits>> -> bytes_to_int(rest, acc * 256 + byte)
    _ -> acc
  }
}

fn encode_int(num: Int, acc: String) -> String {
  case num {
    0 -> acc
    _ -> {
      let char = string_char_at(alphabet, num % 58)
      encode_int(num / 58, char <> acc)
    }
  }
}

fn decode_base58(input: String) -> Result(BitArray, CodecError) {
  let leading_ones = count_leading_char(input, "1", 0)
  case string_to_int(input, 0, 0) {
    Error(e) -> Error(e)
    Ok(num) -> {
      let bytes = int_to_bytes(num, [])
      let leading = list.repeat(0, leading_ones)
      let all_bytes = list.append(leading, bytes)
      Ok(list_to_bit_array(all_bytes, <<>>))
    }
  }
}

fn count_leading_char(input: String, char: String, count: Int) -> Int {
  case string.pop_grapheme(input) {
    Ok(#(c, rest)) if c == char -> count_leading_char(rest, char, count + 1)
    _ -> count
  }
}

fn string_to_int(input: String, acc: Int, pos: Int) -> Result(Int, CodecError) {
  case string.pop_grapheme(input) {
    Error(Nil) -> Ok(acc)
    Ok(#(c, rest)) ->
      case char_value(c) {
        Error(_) -> Error(InvalidCharacter(c, pos))
        Ok(val) -> string_to_int(rest, acc * 58 + val, pos + 1)
      }
  }
}

fn int_to_bytes(num: Int, acc: List(Int)) -> List(Int) {
  case num {
    0 -> acc
    _ -> int_to_bytes(num / 256, [num % 256, ..acc])
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

fn string_char_at(s: String, index: Int) -> String {
  case string.drop_start(s, index) |> string.pop_grapheme {
    Ok(#(c, _)) -> c
    Error(_) -> ""
  }
}

fn list_to_bit_array(bytes: List(Int), acc: BitArray) -> BitArray {
  case bytes {
    [] -> acc
    [b, ..rest] -> list_to_bit_array(rest, bit_array.append(acc, <<b:int>>))
  }
}
