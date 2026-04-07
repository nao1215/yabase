/// Developer-friendly shortcut functions for common encodings.
///
/// Each function delegates directly to the corresponding low-level module.
/// All encode functions are total (return `String`) except `encode_z85`
/// and `encode_rfc1924_base85`, which return `Result(String, CodecError)`
/// because they require input length to be a multiple of 4 bytes.
import yabase/adobe_ascii85
import yabase/ascii85
import yabase/base16
import yabase/base32/clockwork
import yabase/base32/crockford
import yabase/base32/hex as base32_hex
import yabase/base32/rfc4648
import yabase/base32/zbase32
import yabase/base36
import yabase/base45
import yabase/base58/bitcoin as base58_bitcoin
import yabase/base58/flickr as base58_flickr
import yabase/base62
import yabase/base64/dq
import yabase/base64/nopadding
import yabase/base64/standard
import yabase/base64/urlsafe
import yabase/base64/urlsafe_nopadding
import yabase/base91
import yabase/core/encoding.{type CodecError}
import yabase/rfc1924_base85
import yabase/z85

// --- Base16 ---

/// Encode a BitArray to a lowercase hexadecimal string.
pub fn encode_base16(data: BitArray) -> String {
  base16.encode(data)
}

/// Decode a hexadecimal string to a BitArray. Case-insensitive.
pub fn decode_base16(input: String) -> Result(BitArray, CodecError) {
  base16.decode(input)
}

// --- Base32 ---

/// Encode a BitArray to Base32 (RFC 4648) with padding.
pub fn encode_base32(data: BitArray) -> String {
  rfc4648.encode(data)
}

/// Decode a Base32 (RFC 4648) string to a BitArray.
pub fn decode_base32(input: String) -> Result(BitArray, CodecError) {
  rfc4648.decode(input)
}

/// Encode a BitArray to Base32 Hex (extended hex alphabet, RFC 4648) with padding.
pub fn encode_base32_hex(data: BitArray) -> String {
  base32_hex.encode(data)
}

/// Decode a Base32 Hex string to a BitArray.
pub fn decode_base32_hex(input: String) -> Result(BitArray, CodecError) {
  base32_hex.decode(input)
}

/// Encode a BitArray to Crockford's Base32. No padding. Hyphens ignored on decode.
pub fn encode_base32_crockford(data: BitArray) -> String {
  crockford.encode(data)
}

/// Decode a Crockford's Base32 string. O->0, I/L->1, hyphens ignored.
pub fn decode_base32_crockford(input: String) -> Result(BitArray, CodecError) {
  crockford.decode(input)
}

/// Encode a BitArray to Clockwork Base32. No padding, no confusable characters.
pub fn encode_base32_clockwork(data: BitArray) -> String {
  clockwork.encode(data)
}

/// Decode a Clockwork Base32 string. O->0, I/L->1, case-insensitive.
pub fn decode_base32_clockwork(input: String) -> Result(BitArray, CodecError) {
  clockwork.decode(input)
}

/// Encode a BitArray to z-base-32 (human-oriented, no padding).
pub fn encode_zbase32(data: BitArray) -> String {
  zbase32.encode(data)
}

/// Decode a z-base-32 string to a BitArray.
pub fn decode_zbase32(input: String) -> Result(BitArray, CodecError) {
  zbase32.decode(input)
}

// --- Base36 ---

/// Encode a BitArray to Base36 (0-9, a-z). Returns "" for empty input.
pub fn encode_base36(data: BitArray) -> String {
  base36.encode(data)
}

/// Decode a Base36 string to a BitArray. Case-insensitive.
pub fn decode_base36(input: String) -> Result(BitArray, CodecError) {
  base36.decode(input)
}

// --- Base45 ---

/// Encode a BitArray to Base45 (RFC 9285, QR-code friendly).
pub fn encode_base45(data: BitArray) -> String {
  base45.encode(data)
}

/// Decode a Base45 string to a BitArray.
pub fn decode_base45(input: String) -> Result(BitArray, CodecError) {
  base45.decode(input)
}

// --- Base58 ---

/// Encode a BitArray to Base58 (Bitcoin alphabet). Leading zero bytes become '1'.
pub fn encode_base58(data: BitArray) -> String {
  base58_bitcoin.encode(data)
}

/// Decode a Base58 (Bitcoin) string to a BitArray. Leading '1' characters become zero bytes.
pub fn decode_base58(input: String) -> Result(BitArray, CodecError) {
  base58_bitcoin.decode(input)
}

/// Encode a BitArray to Base58 (Flickr alphabet). Same as Bitcoin but with swapped case.
pub fn encode_base58_flickr(data: BitArray) -> String {
  base58_flickr.encode(data)
}

/// Decode a Base58 (Flickr) string to a BitArray.
pub fn decode_base58_flickr(input: String) -> Result(BitArray, CodecError) {
  base58_flickr.decode(input)
}

// --- Base62 ---

/// Encode a BitArray to Base62 (0-9, A-Z, a-z). Returns "" for empty input.
pub fn encode_base62(data: BitArray) -> String {
  base62.encode(data)
}

/// Decode a Base62 string to a BitArray.
pub fn decode_base62(input: String) -> Result(BitArray, CodecError) {
  base62.decode(input)
}

// --- Base64 ---

/// Encode a BitArray to standard Base64 (RFC 4648) with padding.
pub fn encode_base64(data: BitArray) -> String {
  standard.encode(data)
}

/// Decode a standard Base64 string to a BitArray.
pub fn decode_base64(input: String) -> Result(BitArray, CodecError) {
  standard.decode(input)
}

/// Encode a BitArray to URL-safe Base64 (- instead of +, _ instead of /) with padding.
pub fn encode_base64_urlsafe(data: BitArray) -> String {
  urlsafe.encode(data)
}

/// Decode a URL-safe Base64 string to a BitArray.
pub fn decode_base64_urlsafe(input: String) -> Result(BitArray, CodecError) {
  urlsafe.decode(input)
}

/// Encode a BitArray to URL-safe Base64 without padding.
pub fn encode_base64_urlsafe_nopadding(data: BitArray) -> String {
  urlsafe_nopadding.encode(data)
}

/// Decode a URL-safe Base64 string without padding to a BitArray.
pub fn decode_base64_urlsafe_nopadding(
  input: String,
) -> Result(BitArray, CodecError) {
  urlsafe_nopadding.decode(input)
}

/// Encode a BitArray to Base64 without padding characters.
pub fn encode_base64_nopadding(data: BitArray) -> String {
  nopadding.encode(data)
}

/// Decode a Base64 string without padding to a BitArray.
pub fn decode_base64_nopadding(input: String) -> Result(BitArray, CodecError) {
  nopadding.decode(input)
}

/// Encode a BitArray to Base64 DQ (Dragon Quest revival password style, hiragana alphabet).
pub fn encode_base64_dq(data: BitArray) -> String {
  dq.encode(data)
}

/// Decode a Base64 DQ (hiragana) string to a BitArray.
pub fn decode_base64_dq(input: String) -> Result(BitArray, CodecError) {
  dq.decode(input)
}

// --- Base91 ---

/// Encode a BitArray to Base91 (91 printable ASCII characters).
pub fn encode_base91(data: BitArray) -> String {
  base91.encode(data)
}

/// Decode a Base91 string to a BitArray.
pub fn decode_base91(input: String) -> Result(BitArray, CodecError) {
  base91.decode(input)
}

// --- Ascii85 ---

/// Encode a BitArray to Ascii85 (btoa style). All-zero 4-byte groups encode as 'z'.
pub fn encode_ascii85(data: BitArray) -> String {
  ascii85.encode(data)
}

/// Decode an Ascii85 string to a BitArray.
pub fn decode_ascii85(input: String) -> Result(BitArray, CodecError) {
  ascii85.decode(input)
}

// --- Z85 ---

/// Encode a BitArray to Z85 (ZeroMQ variant of Ascii85).
/// Returns `Error(InvalidLength)` if input length is not a multiple of 4 bytes.
pub fn encode_z85(data: BitArray) -> Result(String, CodecError) {
  z85.encode(data)
}

/// Decode a Z85 string to a BitArray. Input length must be a multiple of 5.
pub fn decode_z85(input: String) -> Result(BitArray, CodecError) {
  z85.decode(input)
}

// --- Adobe Ascii85 ---

/// Encode a BitArray to Adobe Ascii85 with <~ ~> delimiters.
pub fn encode_adobe_ascii85(data: BitArray) -> String {
  adobe_ascii85.encode(data)
}

/// Decode an Adobe Ascii85 string (with <~ ~> delimiters) to a BitArray.
pub fn decode_adobe_ascii85(input: String) -> Result(BitArray, CodecError) {
  adobe_ascii85.decode(input)
}

// --- RFC 1924 Base85 ---

/// Encode a BitArray to RFC 1924 Base85.
/// Returns `Error(InvalidLength)` if input length is not a multiple of 4 bytes.
pub fn encode_rfc1924_base85(data: BitArray) -> Result(String, CodecError) {
  rfc1924_base85.encode(data)
}

/// Decode an RFC 1924 Base85 string to a BitArray. Input length must be a multiple of 5.
pub fn decode_rfc1924_base85(input: String) -> Result(BitArray, CodecError) {
  rfc1924_base85.decode(input)
}
