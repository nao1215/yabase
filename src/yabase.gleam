//// Binary-to-text encodings, multibase prefixes, and canonical integer IDs.
////
//// Use `encode` and `decode` with an `Encoding` value. Both return a `Result`:
//// encoders reject partial bytes, and decoders report typed errors with original
//// input positions. `decode_multibase` detects the prefix and returns a `Decoded`
//// record. Base58Check and Bech32 have separate decoders that return their metadata.
////
//// ```gleam
//// import yabase
////
//// pub fn main() {
////   let assert True = yabase.encode(<<"Hello":utf8>>, using: yabase.Base64)
////     == Ok("SGVsbG8=")
////   let assert True = yabase.decode("SGVsbG8=", using: yabase.Base64)
////     == Ok(<<"Hello":utf8>>)
//// }
//// ```
////
//// Byte codecs run on Erlang and JavaScript. Integer operations use minimal,
//// canonical representations and support an optional inclusive upper bound when
//// decoding. JavaScript integers are limited to `int53_max`; Erlang retains
//// arbitrary precision. These integer limits do not restrict byte payload sizes.
////
//// See `Encoding` for formats and `CodecError` for diagnostics. Strict hexadecimal,
//// RFC4648 Base32, and standard Base64 decoders are available when accepted wire
//// text must exactly match the encoder's output.

import gleam/bit_array
import gleam/bool
import gleam/dict.{type Dict}
import gleam/int
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/result
import gleam/string
import yabase/internal/sha256

/// Select a binary-to-text format.
///
/// Construct selections directly and pass them to `encode` or `decode`.
/// Base58Check versions and Bech32 HRPs are validated by those operations.
/// Integer operations support the ten selections listed under `encode_int`.
/// Use `multibase_prefix` to check multibase support.
pub type Encoding {
  /// Encode each byte as eight binary digits.
  Base2
  /// Treat the bytes as an unsigned number written in octal. Multibase uses three-bit packing instead.
  Base8
  /// Treat the bytes as an unsigned decimal number.
  Base10
  /// Encode two uppercase hexadecimal digits per byte; decode either ASCII case.
  Base16
  /// Encode lowercase hexadecimal; decode either ASCII case. Integer operations are unsupported.
  Base16Lowercase
  /// Encode padded RFC4648 Base32; ordinary decoding also accepts lowercase and omitted padding.
  Base32Rfc4648
  /// Encode padded Base32 Hex; ordinary decoding also accepts lowercase and omitted padding.
  Base32Hex
  /// Encode a number using Crockford Base32. Byte decoding accepts O/I/L aliases and ignores hyphens.
  Base32Crockford
  /// Append a modulo-37 check symbol to numeric Crockford Base32.
  Base32CrockfordCheck
  /// Pack bytes into Clockwork Base32 symbols; this differs from numeric Crockford encoding.
  Base32Clockwork
  /// Encode unpadded z-base-32 with its own alphabet.
  Zbase32
  /// Encode a number with digits and lowercase letters; byte decoding accepts either ASCII case.
  Base36
  /// Pack two bytes into three RFC9285 Base45 digits, or one byte into two digits.
  Base45
  /// Encode a number using the Bitcoin Base58 alphabet.
  Base58Bitcoin
  /// Encode a number using the Flickr Base58 alphabet.
  Base58Flickr
  /// Prefix a version byte from 0 through 255 and append a four-byte double-SHA256 checksum.
  Base58Check(version: Int)
  /// Encode a number using digits, uppercase letters, then lowercase letters.
  Base62
  /// Encode padded standard Base64.
  Base64
  /// Encode padded URL-safe Base64.
  Base64UrlSafe
  /// Encode standard Base64 without padding; decoding rejects padding characters.
  Base64NoPadding
  /// Encode URL-safe Base64 without padding; decoding rejects padding characters.
  Base64UrlSafeNoPadding
  /// Encode Base64 with a hiragana alphabet and `・` padding.
  Base64Dq
  /// Encode btoa-style Ascii85, including zero and space abbreviations.
  Ascii85
  /// Encode Adobe Ascii85 between `<~` and `~>`, with the zero abbreviation.
  AdobeAscii85
  /// Encode complete four-byte groups using the RFC1924 alphabet.
  Rfc1924Base85
  /// Encode complete four-byte groups using the ZeroMQ Z85 alphabet.
  Z85
  /// Encode bytes using variable thirteen- or fourteen-bit basE91 groups.
  Base91
  /// Encode a byte payload with a lowercase printable-ASCII HRP and the selected checksum. The complete wire is limited to 90 characters.
  Bech32Encoding(hrp: String, variant: Bech32Variant)
}

/// Select the original BIP 173 checksum or the BIP 350 Bech32m checksum.
pub type Bech32Variant {
  /// Use the original BIP 173 checksum.
  Bech32
  /// Use the BIP 350 Bech32m checksum.
  Bech32m
}

/// Hold decoded multibase bytes and their canonical encoding selection.
pub type Decoded {
  Decoded(encoding: Encoding, data: BitArray)
}

/// Hold the verified Base58Check version byte and payload.
pub type Base58CheckDecoded {
  Base58CheckDecoded(version: Int, payload: BitArray)
}

/// Hold a verified Bech32 payload, lowercase HRP, and checksum variant.
pub type Bech32Decoded {
  Bech32Decoded(hrp: String, data: BitArray, variant: Bech32Variant)
}

/// Describe an encoding or decoding failure.
///
/// `InvalidCharacter` contains the original grapheme and its zero-based
/// index in the public input, including ignored characters and multibase
/// prefixes. CRLF counts as one grapheme. `MissingDelimiter` instead reports
/// an insertion boundary in that same grapheme coordinate system.
///
/// `InvalidLength` keeps the format's length unit: usually input graphemes,
/// but decoded bytes for Base58Check, bytes for Z85/RFC1924 encoding, and
/// the relevant data segment for Bech32. Ascii85 tail errors use the parser's
/// cursor count; Adobe adds its two-character opening delimiter. It is not
/// an invalid-character position. `UnalignedInput` always counts bits.
pub type CodecError {
  /// An input grapheme is not allowed at its position in this format.
  InvalidCharacter(character: String, position: Int)
  /// The input or a decoded group has an invalid length; see the type-level unit rules.
  InvalidLength(length: Int)
  /// A numeric group, target integer range, or explicit integer bound was exceeded.
  Overflow
  /// The first multibase grapheme is not registered.
  UnsupportedPrefix(prefix: String)
  /// The selected format has no assigned multibase prefix.
  UnsupportedMultibaseEncoding(encoding_name: String)
  /// Checksum verification failed.
  InvalidChecksum
  /// The Bech32 human-readable part violates its length, character, or encoding-case requirements.
  InvalidHrp(reason: String)
  /// Decoding succeeded, but the wire or integer payload is not in the required canonical form.
  NonCanonical
  /// The selected format has no supported integer representation.
  UnsupportedForInt(encoding_name: String)
  /// An integer encoder received a negative value.
  NegativeValue(value: Int)
  /// The input bit array is not a whole number of bytes.
  UnalignedInput(bit_size: Int)
  /// The expected or encoded Base58Check version is outside 0 through 255.
  InvalidVersion(version: Int)
  /// The verified wire version differs from the expected version.
  UnexpectedVersion(expected: Int, actual: Int)
  /// The verified lowercase HRP differs from the expected string.
  UnexpectedHrp(expected: String, actual: String)
  /// The verified checksum variant differs from the expected variant.
  UnexpectedBech32Variant(expected: Bech32Variant, actual: Bech32Variant)
  /// Bech32 wire text contains both lowercase and uppercase ASCII letters.
  MixedCase
  /// A verified Bech32 payload has nonzero unused bits.
  NonZeroPadding
  /// An Adobe Ascii85 opening or closing delimiter is missing at the reported insertion boundary.
  MissingDelimiter(expected: String, position: Int)
}

/// The largest exactly supported JavaScript integer: 2^53 − 1, on both targets.
pub const int53_max: Int = 9_007_199_254_740_991

@target(erlang)
/// The signed 64-bit maximum on Erlang; the JavaScript-safe maximum on JavaScript.
pub const int64_max: Int = 9_223_372_036_854_775_807

@target(javascript)
/// The signed 64-bit maximum on Erlang; the JavaScript-safe maximum on JavaScript.
pub const int64_max: Int = 9_007_199_254_740_991

/// Encode whole bytes using the selected format.
///
/// Returns `UnalignedInput` for a partial byte. Base58Check validates its
/// version first; Bech32 validates its lowercase HRP first and limits the
/// complete output to 90 characters. Z85 and RFC1924 Base85 require a
/// multiple of four bytes. Other format details are listed under `Encoding`.
///
/// ## Examples
///
/// ```gleam
/// encode(<<"Hello":utf8>>, using: Base64)
/// // Ok("SGVsbG8=")
///
/// encode(<<1:size(1)>>, using: Base64)
/// // Error(UnalignedInput(1))
/// ```
pub fn encode(
  data: BitArray,
  using encoding: Encoding,
) -> Result(String, CodecError) {
  case encoding {
    Base58Check(version) -> base58check_encode(version, data)
    Bech32Encoding(hrp, variant) -> bech32_encode_variant(variant, hrp, data)
    _ -> {
      use _ <- result.try(check_byte_alignment(data))
      encoding_encode(encoding, data)
    }
  }
}

/// Decode text using the selected format.
///
/// Byte decoders preserve leading zero bytes and apply the format's normal
/// alphabet and padding rules. Use the three strict decoders when the wire
/// text must match their canonical encoding.
///
/// For Base58Check and Bech32, decode and verify the wire checksum before
/// validating or comparing the expected metadata. A valid checksum with
/// different metadata returns `UnexpectedVersion`, `UnexpectedHrp`, or
/// `UnexpectedBech32Variant`. Expected HRPs are compared literally: `"BC"`
/// does not match a decoded `"bc"`.
///
/// ## Examples
///
/// ```gleam
/// decode("00FF", using: Base16)
/// // Ok(<<0, 255>>)
///
/// decode("0!", using: Base16)
/// // Error(InvalidCharacter("!", 1))
/// ```
pub fn decode(
  value: String,
  using encoding: Encoding,
) -> Result(BitArray, CodecError) {
  encoding_decode_as(encoding, value)
}

/// Decode canonical uppercase hexadecimal text.
///
/// Returns normal decoding errors first, then `NonCanonical` if re-encoding
/// the bytes would change the input. Requires two characters per byte.
///
/// ## Examples
///
/// ```gleam
/// decode_base16_strict("0F")
/// // Ok(<<15>>)
/// decode_base16_strict("0f")
/// // Error(NonCanonical)
/// ```
pub fn decode_base16_strict(value: String) -> Result(BitArray, CodecError) {
  base16_decode_strict(value)
}

/// Decode canonical padded RFC4648 Base32 text.
///
/// Returns normal decoding errors first, then `NonCanonical` for lowercase,
/// missing padding, or nonzero unused pad bits.
///
/// ## Examples
///
/// ```gleam
/// decode_base32_strict("MY======")
/// // Ok(<<102>>)
/// decode_base32_strict("my======")
/// // Error(NonCanonical)
/// ```
pub fn decode_base32_strict(value: String) -> Result(BitArray, CodecError) {
  base32_rfc4648_decode_strict(value)
}

/// Decode canonical padded standard Base64 text.
///
/// Returns normal decoding errors first, then `NonCanonical` if the input
/// differs from the encoder's output, including nonzero unused pad bits.
///
/// ## Examples
///
/// ```gleam
/// decode_base64_strict("TQ==")
/// // Ok(<<77>>)
/// decode_base64_strict("TR==")
/// // Error(NonCanonical)
/// ```
pub fn decode_base64_strict(value: String) -> Result(BitArray, CodecError) {
  base64_standard_decode_strict(value)
}

/// Verify a Base58Check checksum and return the version and payload.
///
/// Accepts any version byte and an empty payload. The decoded wire must
/// contain a version byte and four checksum bytes. Use `decode` with
/// `Base58Check(version)` to require a particular version.
///
/// ## Examples
///
/// ```gleam
/// decode_base58check("18AV53K")
/// // Ok(Base58CheckDecoded(0, <<1>>))
/// decode_base58check("!")
/// // Error(InvalidCharacter("!", 0))
/// ```
pub fn decode_base58check(
  value: String,
) -> Result(Base58CheckDecoded, CodecError) {
  base58check_decode(value)
}

/// Verify Bech32 or Bech32m text and return its HRP, bytes, and variant.
///
/// Accepts lowercase or uppercase wire text and returns a lowercase HRP.
/// Rejects mixed case, invalid checksums, and nonzero unused payload bits.
/// Uses the last `1` separator and limits the input to 90 graphemes.
/// The payload is decoded from five-bit symbols to bytes; this operation
/// does not validate SegWit witness versions or program lengths.
///
/// ## Examples
///
/// ```gleam
/// decode_bech32("A12UEL5L")
/// // Ok(Bech32Decoded("a", <<>>, Bech32))
/// decode_bech32("a12UEL5L")
/// // Error(MixedCase)
/// ```
pub fn decode_bech32(value: String) -> Result(Bech32Decoded, CodecError) {
  bech32_decode(value)
}

/// Encode bytes with the selected format's canonical multibase prefix.
///
/// Checks registry support before byte alignment. Returns
/// `UnsupportedMultibaseEncoding` when no prefix is assigned. Hex, Base32,
/// Base32 Hex, and Base36 emit their canonical lowercase wire forms.
/// Multibase Base8 uses three-bit packing; standalone Base8 treats the bytes
/// as a number.
///
/// ## Examples
///
/// ```gleam
/// encode_multibase(<<"Hello":utf8>>, using: Base16)
/// // Ok("f48656c6c6f")
/// encode_multibase(<<>>, using: Base64Dq)
/// // Error(UnsupportedMultibaseEncoding("base64dq"))
/// ```
pub fn encode_multibase(
  data: BitArray,
  using encoding: Encoding,
) -> Result(String, CodecError) {
  multibase_encode_with_prefix(encoding, data)
}

/// Detect the first grapheme as a multibase prefix and decode its payload.
///
/// Returns the canonical encoding selection and decoded bytes. Accepted
/// alias prefixes do not survive in the result. Invalid-character positions
/// include the prefix and refer to the original input.
///
/// ## Examples
///
/// ```gleam
/// decode_multibase("F00")
/// // Ok(Decoded(Base16, <<0>>))
/// decode_multibase("f0!")
/// // Error(InvalidCharacter("!", 2))
/// ```
pub fn decode_multibase(value: String) -> Result(Decoded, CodecError) {
  multibase_decode(value)
}

/// Encode a nonnegative integer in its canonical text form.
///
/// Supports Base10, Base16, RFC4648 Base32, Crockford Base32 with or without
/// its check symbol, Base36, Bitcoin or Flickr Base58, Base58Check, and
/// Base62. Checks format support before rejecting negative or out-of-range
/// values. JavaScript is limited to `int53_max`; Erlang supports arbitrary
/// precision. Base58Check validates its version after numeric admission.
///
/// Zero is encoded from one zero byte. Base16 emits an even number of
/// uppercase digits; use `encode_int_base16_compact` to omit an unnecessary
/// leading zero nibble.
///
/// ## Examples
///
/// ```gleam
/// encode_int(42, using: Base58Bitcoin)
/// // Ok("j")
/// encode_int(-1, using: Base58Bitcoin)
/// // Error(NegativeValue(-1))
/// ```
pub fn encode_int(
  value: Int,
  using encoding: Encoding,
) -> Result(String, CodecError) {
  intid_encode_int(encoding: encoding, value: value)
}

/// Encode a nonnegative integer as compact uppercase hexadecimal text.
///
/// Omits an unnecessary leading zero nibble and encodes zero as `"0"`.
/// JavaScript values above `int53_max` return `Overflow`.
///
/// ## Examples
///
/// ```gleam
/// encode_int_base16_compact(15)
/// // Ok("F")
/// encode_int_base16_compact(-1)
/// // Error(NegativeValue(-1))
/// ```
pub fn encode_int_base16_compact(value: Int) -> Result(String, CodecError) {
  intid_encode_int_base16_compact(value)
}

/// Decode canonical integer text with an optional inclusive upper bound.
///
/// Supports the same ten formats as `encode_int`. Rejects empty input,
/// redundant leading zero bytes, alternate case, and Crockford aliases or
/// hyphens. Base16 accepts both uppercase byte-aligned and compact forms,
/// including `"00"` and `"0"` for zero.
///
/// Checks format support, syntax and metadata, target range, canonicality,
/// then the optional bound. `None` leaves only the target's range limit;
/// `Some(maximum)` adds an inclusive bound. A negative bound returns
/// `Overflow` after the earlier checks pass. JavaScript is limited to
/// `int53_max`; Erlang supports arbitrary precision.
///
/// ## Examples
///
/// ```gleam
/// import gleam/option.{Some}
///
/// decode_int("F", using: Base16, up_to: Some(15))
/// // Ok(15)
/// decode_int("F", using: Base16, up_to: Some(14))
/// // Error(Overflow)
/// ```
pub fn decode_int(
  value: String,
  using encoding: Encoding,
  up_to maximum: Option(Int),
) -> Result(Int, CodecError) {
  use decoded <- result.try(intid_decode_int(encoding: encoding, value: value))
  optional_bound(decoded, maximum)
}

/// Decode a canonical Base58Check integer without requiring a version.
///
/// Verifies the checksum and accepts any version byte. The payload must be
/// nonempty and use the minimal unsigned integer representation, with one
/// zero byte for zero. Checks target range and canonicality before the
/// optional inclusive bound. Use `decode_int` with `Base58Check(version)`
/// when the version must match.
///
/// ## Examples
///
/// ```gleam
/// import gleam/option.{None}
///
/// decode_int_base58check("26k9aD1PF", up_to: None)
/// // Ok(1)
/// decode_int_base58check("5rLWbXvFUx", up_to: None)
/// // Error(NonCanonical)
/// ```
pub fn decode_int_base58check(
  value: String,
  up_to maximum: Option(Int),
) -> Result(Int, CodecError) {
  use decoded <- result.try(intid_decode_int_base58check(value))
  optional_bound(decoded, maximum)
}

/// Return the stable display name of an encoding selection.
///
/// Does not validate version or HRP parameters. Bech32 and Bech32m have
/// different names; lowercase hexadecimal is named `"base16lower"`.
///
/// ## Examples
///
/// ```gleam
/// encoding_to_string(Base64)
/// // "base64pad"
/// encoding_to_string(Bech32Encoding("bc", Bech32m))
/// // "bech32m"
/// ```
pub fn encoding_to_string(encoding: Encoding) -> String {
  encoding_multibase_name(encoding)
}

/// Return the canonical multibase prefix for an encoding selection.
///
/// Returns `Error(Nil)` for an unsupported format. This registry lookup does
/// not validate version or HRP parameters. Both hexadecimal selections use
/// `"f"`.
///
/// ## Examples
///
/// ```gleam
/// multibase_prefix(Base16Lowercase)
/// // Ok("f")
/// multibase_prefix(Base58Check(0))
/// // Error(Nil)
/// ```
pub fn multibase_prefix(encoding: Encoding) -> Result(String, Nil) {
  encoding_multibase_prefix(encoding)
}

/// Look up a complete multibase prefix string.
///
/// Accepts registered canonical prefixes and decode-only aliases. Returns
/// `Error(Nil)` for empty, multi-character, or unknown input. Hexadecimal
/// prefixes both select `Base16`.
///
/// ## Examples
///
/// ```gleam
/// encoding_from_multibase_prefix("F")
/// // Ok(Base16)
/// encoding_from_multibase_prefix("ff")
/// // Error(Nil)
/// ```
pub fn encoding_from_multibase_prefix(prefix: String) -> Result(Encoding, Nil) {
  encoding_from_multibase_prefix_impl(prefix)
}

fn optional_bound(value: Int, maximum: Option(Int)) -> Result(Int, CodecError) {
  case maximum {
    None -> Ok(value)
    Some(maximum) -> intid_bound_check(value, maximum)
  }
}

const adobe_ascii85_prefix = "<~"

const adobe_ascii85_suffix = "~>"

// Encode a BitArray to Adobe Ascii85 with <~ ~> delimiters.
//
// Called after whole-byte validation.
fn adobe_ascii85_encode(data: BitArray) -> String {
  adobe_ascii85_prefix
  <> base85_encode(data, base85_ascii85_alphabet(), ZeroShortcut)
  <> adobe_ascii85_suffix
}

// Decode an Adobe Ascii85 string (with <~ ~> delimiters) to a BitArray.
fn adobe_ascii85_decode(input: String) -> Result(BitArray, CodecError) {
  let bytes = bit_array.from_string(input)
  let #(start, end) = adobe_trim_span(string.to_utf_codepoints(input), 0, -1, 0)
  let trimmed = source_slice(bytes, start, end - start)
  use <- bool.guard(
    when: !string.starts_with(trimmed, adobe_ascii85_prefix),
    return: Error(MissingDelimiter(
      adobe_ascii85_prefix,
      source_position(input, start),
    )),
  )
  use <- bool.guard(
    when: !string.ends_with(trimmed, adobe_ascii85_suffix),
    return: Error(MissingDelimiter(
      adobe_ascii85_suffix,
      source_position(input, end - 1) + 1,
    )),
  )
  // Preserve the historical overlapping empty delimiters explicitly.
  use <- bool.guard(when: trimmed == "<~>", return: Ok(<<>>))
  let inner = source_slice(bytes, start + 2, end - start - 4)
  base85_decode_ascii85(inner, ZeroShortcut, 2, DecodeSource(input, start + 2))
}

// Encode a BitArray to Ascii85.
//
// Called after whole-byte validation.
fn ascii85_encode(data: BitArray) -> String {
  base85_encode(data, base85_ascii85_alphabet(), ZeroAndSpaceShortcuts)
}

// Decode an Ascii85 string to a BitArray.
fn ascii85_decode(input: String) -> Result(BitArray, CodecError) {
  base85_decode_ascii85(input, ZeroAndSpaceShortcuts, 0, DecodeSource(input, 0))
}

const base10_symbols = "0123456789"

// Encode a BitArray to a decimal string.
//
// Called after whole-byte validation.
fn base10_encode(data: BitArray) -> String {
  bignum_encode(data, alphabet_new(base10_symbols, CaseSensitive))
}

// Decode a decimal string to a BitArray.
fn base10_decode(input: String) -> Result(BitArray, CodecError) {
  bignum_decode(input, alphabet_new(base10_symbols, CaseSensitive))
}

const base16_upper_symbols = "0123456789ABCDEF"

// Encode a BitArray to an uppercase hexadecimal string per
// RFC 4648 §8 (the canonical Base 16 encoding).
//
// Use `encode_lowercase/1` when interoperating with tools that
// emit lowercase hex (e.g. `sha256sum`, IPFS multibase prefix `f`,
// many JSON Web Token implementations); the decoder accepts either
// case, so round-trips work in both directions.
fn base16_encode(data: BitArray) -> String {
  bit_array.base16_encode(data)
}

// Encode a BitArray to a lowercase hexadecimal string. Use this
// when interoperating with tools that expect the lowercase variant
// (`sha256sum` shell output, IPFS multibase prefix `f`, etc.). The
// canonical RFC 4648 §8 form is uppercase — see `encode/1`.
fn base16_encode_lowercase(data: BitArray) -> String {
  bit_array.base16_encode(data) |> string.lowercase
}

// Decode a hexadecimal string to a BitArray.
fn base16_decode(input: String) -> Result(BitArray, CodecError) {
  bitgroup_decode_exact(
    input,
    4,
    alphabet_new(base16_upper_symbols, FoldToLower),
  )
}

// Decode `input` and additionally reject non-canonical encodings
// per RFC 4648 §8: the canonical Base 16 form is uppercase
// (`0-9 A-F`). Useful for HMAC / TOTP / WebAuthn / content-
// addressable storage and any signature-verification context where
// the encoded string itself is part of the contract — strict mode
// rejects the lowercase form (`encode_lowercase/1`'s output) as
// non-canonical even though it decodes to the same bytes through
// the lenient `decode/1`.
//
// Returns `Error(NonCanonical)` when the input is not byte-equal
// to `encode(decode(input))`. Other failure modes
// (`InvalidCharacter`, `InvalidLength`) are surfaced unchanged from
// `decode/1`.
fn base16_decode_strict(input: String) -> Result(BitArray, CodecError) {
  case base16_decode(input) {
    Error(e) -> Error(e)
    Ok(bytes) ->
      case base16_encode(bytes) == input {
        True -> Ok(bytes)
        False -> Error(NonCanonical)
      }
  }
}

fn base2_binary() -> Alphabet {
  alphabet_new("01", CaseSensitive)
}

// Encode a BitArray to a binary string (e.g. <<0x41>> -> "01000001").
//
// Called after whole-byte validation; the byte walker consumes every byte.
fn base2_encode(data: BitArray) -> String {
  bitgroup_encode(data, 1, base2_binary(), Unpadded)
}

// Decode a binary string to a BitArray.
// Input length must be a multiple of 8. Only "0" and "1" are valid.
fn base2_decode(input: String) -> Result(BitArray, CodecError) {
  bitgroup_decode_exact(input, 1, base2_binary())
}

fn base32_clockwork_clockwork() -> Alphabet {
  alphabet_with_extras(
    symbols: "0123456789ABCDEFGHJKMNPQRSTVWXYZ",
    folding: FoldToUpper,
    aliases: [#("O", 0), #("I", 1), #("L", 1)],
    ignore: "",
  )
}

// Encode a BitArray to Clockwork Base32 (no padding).
//
// Called after whole-byte validation.
fn base32_clockwork_encode(data: BitArray) -> String {
  bitgroup_encode(data, 5, base32_clockwork_clockwork(), Unpadded)
}

// Decode a Clockwork Base32 string to a BitArray.
// Case-insensitive. o/O->0, i/I/l/L->1.
//
// Non-alphabet characters (whitespace, CR/LF, punctuation outside
// Clockwork's accepted set) are rejected with `InvalidCharacter`
// carrying the offending byte and its position. The alphabet
// check runs before the length check so the caller does not see
// a misleading `InvalidLength` when the real fault is an
// out-of-alphabet byte.
fn base32_clockwork_decode(input: String) -> Result(BitArray, CodecError) {
  bitgroup_decode_unpadded(input, 5, base32_clockwork_clockwork())
}

const base32_crockford_symbols = "0123456789ABCDEFGHJKMNPQRSTVWXYZ"

const base32_crockford_check_symbols = "0123456789ABCDEFGHJKMNPQRSTVWXYZ*~$=U"

fn base32_crockford_crockford_alphabet() -> Alphabet {
  alphabet_with_extras(
    symbols: base32_crockford_symbols,
    folding: FoldToUpper,
    aliases: [#("O", 0), #("I", 1), #("L", 1)],
    ignore: "-",
  )
}

// Encode a BitArray to a Crockford Base32 string (bignum shape).
//
// Preserves leading zero bytes as '0' characters; the remaining length
// depends on the numeric magnitude. For fixed-width groups, use
// [`yabase/base32/rfc4648.encode`](./rfc4648.html#encode).
fn base32_crockford_encode(data: BitArray) -> String {
  bignum_encode(data, base32_crockford_crockford_alphabet())
}

// Decode a Crockford Base32 string to a BitArray.
// Accepts hyphens (ignored). O->0, I/L->1. Case-insensitive.
fn base32_crockford_decode(input: String) -> Result(BitArray, CodecError) {
  bignum_decode(input, base32_crockford_crockford_alphabet())
}

// Encode a BitArray to Crockford Base32 with a check symbol appended.
// The check symbol is computed as the numeric value of the data mod 37,
// mapped to the 32-character Crockford alphabet followed by *~$=U.
fn base32_crockford_encode_check(data: BitArray) -> String {
  base32_crockford_encode(data) <> base32_crockford_check_symbol(data)
}

// Decode a Crockford Base32 string with check symbol verification.
// The last character is the check symbol; the rest is the encoded data.
// Returns Error(InvalidChecksum) if the check symbol does not match.
fn base32_crockford_decode_check(
  input: String,
) -> Result(BitArray, CodecError) {
  let length = string.length(input)
  case length < 1 {
    True -> Error(InvalidLength(0))
    False -> {
      let body = string.slice(input, 0, length - 1)
      let check = string.slice(input, length - 1, 1)
      let check = case bit_array.from_string(check) {
        <<_>> -> string.uppercase(check)
        _ -> check
      }
      case base32_crockford_decode(body) {
        Error(error) -> Error(error)
        Ok(data) ->
          case check == base32_crockford_check_symbol(data) {
            True -> Ok(data)
            False -> Error(InvalidChecksum)
          }
      }
    }
  }
}

fn base32_crockford_check_symbol(data: BitArray) -> String {
  let check_alphabet = alphabet_new(base32_crockford_check_symbols, FoldToUpper)
  alphabet_to_string([
    alphabet_symbol(check_alphabet, bignum_remainder(data, 37)),
  ])
}

const base32_hex_symbols = "0123456789ABCDEFGHIJKLMNOPQRSTUV"

// Encode a BitArray to Base32 Hex string with padding.
//
// Called after whole-byte validation.
fn base32_hex_encode(data: BitArray) -> String {
  bitgroup_encode(
    data,
    5,
    alphabet_new(base32_hex_symbols, FoldToUpper),
    PaddedTo(8),
  )
}

// Decode a Base32 Hex string to a BitArray.
//
// Non-alphabet characters (whitespace, CR/LF, punctuation outside
// `0-9`, `A-V`, and `=`) are rejected with `InvalidCharacter`
// carrying the offending byte and its position. The alphabet check
// runs before the length check so the caller does not see a
// misleading `InvalidLength` when the real fault is an
// out-of-alphabet byte.
fn base32_hex_decode(input: String) -> Result(BitArray, CodecError) {
  bitgroup_decode_base32_padded(
    input,
    alphabet_new(base32_hex_symbols, FoldToUpper),
  )
}

const base32_rfc4648_symbols = "ABCDEFGHIJKLMNOPQRSTUVWXYZ234567"

// Encode a BitArray to a Base32 string with padding.
//
// Called after whole-byte validation.
fn base32_rfc4648_encode(data: BitArray) -> String {
  bitgroup_encode(
    data,
    5,
    alphabet_new(base32_rfc4648_symbols, FoldToUpper),
    PaddedTo(8),
  )
}

// Decode a Base32 string (with or without padding) to a BitArray.
//
// Non-alphabet characters (whitespace, CR/LF, punctuation outside
// `A-Z`, `2-7`, and `=`) are rejected with `InvalidCharacter`
// carrying the offending byte and its position. The alphabet check
// runs before the length check so the caller does not see a
// misleading `InvalidLength` when the real fault is an
// out-of-alphabet byte.
fn base32_rfc4648_decode(input: String) -> Result(BitArray, CodecError) {
  bitgroup_decode_base32_padded(
    input,
    alphabet_new(base32_rfc4648_symbols, FoldToUpper),
  )
}

// Decode `input` and additionally reject non-canonical encodings
// per RFC 4648 §3.5 / §6: the canonical form is the uppercase,
// padded shape produced by `encode/1`, and any deviation
// (lowercase, mixed case, missing padding, non-zero pad bits in a
// final partial block) is rejected with `Error(NonCanonical)`.
// Useful for signature verification, content-addressable storage,
// and replay-attack-resistant token handling, where the wire
// encoding's uniqueness is part of the contract.
//
// Returns `Error(NonCanonical)` when the input is not byte-equal
// to `encode(decode(input))`. Other failure modes
// (`InvalidCharacter`, `InvalidLength`) are surfaced unchanged from
// `decode/1`.
fn base32_rfc4648_decode_strict(input: String) -> Result(BitArray, CodecError) {
  case base32_rfc4648_decode(input) {
    Error(e) -> Error(e)
    Ok(bytes) ->
      case base32_rfc4648_encode(bytes) == input {
        True -> Ok(bytes)
        False -> Error(NonCanonical)
      }
  }
}

const base32_zbase32_symbols = "ybndrfg8ejkmcpqxot1uwisza345h769"

// Encode a BitArray to z-base-32 (no padding).
//
// Called after whole-byte validation.
fn base32_zbase32_encode(data: BitArray) -> String {
  bitgroup_encode(
    data,
    5,
    alphabet_new(base32_zbase32_symbols, FoldToLower),
    Unpadded,
  )
}

// Decode a z-base-32 string to a BitArray.
//
// Non-alphabet characters (whitespace, CR/LF, punctuation outside
// z-base-32's accepted set) are rejected with `InvalidCharacter`
// carrying the offending byte and its position. The alphabet check
// runs before the length check so the caller does not see a
// misleading `InvalidLength` when the real fault is an
// out-of-alphabet byte.
fn base32_zbase32_decode(input: String) -> Result(BitArray, CodecError) {
  bitgroup_decode_unpadded(
    input,
    5,
    alphabet_new(base32_zbase32_symbols, FoldToLower),
  )
}

const base36_symbols = "0123456789abcdefghijklmnopqrstuvwxyz"

// Encode a BitArray to Base36 (lowercase).
//
// Called after whole-byte validation.
fn base36_encode(data: BitArray) -> String {
  bignum_encode(data, alphabet_new(base36_symbols, FoldToLower))
}

// Decode a Base36 string to a BitArray.
fn base36_decode(input: String) -> Result(BitArray, CodecError) {
  bignum_decode(input, alphabet_new(base36_symbols, FoldToLower))
}

fn base45_base45() -> Alphabet {
  alphabet_new("0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ $%*+-./:", CaseSensitive)
}

// Encode a BitArray to Base45.
//
// Called after whole-byte validation.
fn base45_encode(data: BitArray) -> String {
  base45_encode_loop(data, base45_base45(), [])
}

fn base45_encode_loop(
  data: BitArray,
  alphabet: Alphabet,
  acc: List(Int),
) -> String {
  case data {
    <<value:16, rest:bytes>> ->
      base45_encode_loop(rest, alphabet, [
        alphabet_symbol(alphabet, value / 2025),
        alphabet_symbol(alphabet, value / 45 % 45),
        alphabet_symbol(alphabet, value % 45),
        ..acc
      ])
    <<value>> ->
      [
        alphabet_symbol(alphabet, value / 45),
        alphabet_symbol(alphabet, value % 45),
        ..acc
      ]
      |> list.reverse
      |> alphabet_to_string
    _ -> alphabet_to_string(list.reverse(acc))
  }
}

// Decode a Base45 string to a BitArray.
fn base45_decode(input: String) -> Result(BitArray, CodecError) {
  let bytes = bit_array.from_string(input)
  let length = alphabet_character_count(input, bytes)
  case length % 3 {
    1 -> Error(InvalidLength(length))
    _ -> base45_decode_loop(bytes, bytes, base45_base45(), 0, [])
  }
}

fn base45_decode_loop(
  input: BitArray,
  rest: BitArray,
  alphabet: Alphabet,
  offset: Int,
  acc: List(BitArray),
) -> Result(BitArray, CodecError) {
  case rest {
    <<c, d, e, rest:bytes>> ->
      case base45_digits([c, d, e], alphabet, offset, 0, 1) {
        Ok(value) if value > 65_535 -> Error(Overflow)
        Ok(value) ->
          base45_decode_loop(input, rest, alphabet, offset + 3, [
            <<value:16>>,
            ..acc
          ])
        Error(bad) ->
          Error(alphabet_invalid_character(alphabet, input, bad, bad))
      }
    <<c, d>> ->
      case base45_digits([c, d], alphabet, offset, 0, 1) {
        Ok(value) if value > 255 -> Error(Overflow)
        Ok(value) -> Ok(bit_array.concat(list.reverse([<<value>>, ..acc])))
        Error(bad) ->
          Error(alphabet_invalid_character(alphabet, input, bad, bad))
      }
    _ -> Ok(bit_array.concat(list.reverse(acc)))
  }
}

// The value of base-45 digits written least significant first, or the
// offset of the first byte that is not a symbol.
fn base45_digits(
  group: List(Int),
  alphabet: Alphabet,
  offset: Int,
  value: Int,
  weight: Int,
) -> Result(Int, Int) {
  case group {
    [] -> Ok(value)
    [byte, ..rest] ->
      case alphabet_lookup(alphabet, byte) {
        Value(digit) ->
          base45_digits(
            rest,
            alphabet,
            offset + 1,
            value + digit * weight,
            weight * 45,
          )
        Ignored | Invalid -> Error(offset)
      }
  }
}

const base58_bitcoin_symbols =
  "123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz"

// Encode a BitArray to Base58 (Bitcoin).
//
// Called after whole-byte validation.
fn base58_bitcoin_encode(data: BitArray) -> String {
  bignum_encode(data, alphabet_new(base58_bitcoin_symbols, CaseSensitive))
}

// Decode a Base58 string to a BitArray.
fn base58_bitcoin_decode(input: String) -> Result(BitArray, CodecError) {
  bignum_decode(input, alphabet_new(base58_bitcoin_symbols, CaseSensitive))
}

const base58_flickr_symbols =
  "123456789abcdefghijkmnopqrstuvwxyzABCDEFGHJKLMNPQRSTUVWXYZ"

// Encode a BitArray to Base58 (Flickr).
//
// Called after whole-byte validation.
fn base58_flickr_encode(data: BitArray) -> String {
  bignum_encode(data, alphabet_new(base58_flickr_symbols, CaseSensitive))
}

// Decode a Base58 string (Flickr alphabet) to a BitArray.
fn base58_flickr_decode(input: String) -> Result(BitArray, CodecError) {
  bignum_decode(input, alphabet_new(base58_flickr_symbols, CaseSensitive))
}

const base58check_symbols =
  "123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz"

// Encode a version byte (0..255) and payload to Base58Check.
// Validate version 0..255 before whole-byte alignment, retaining the input
// version or bit count in InvalidVersion or UnalignedInput.
fn base58check_encode(
  version: Int,
  payload: BitArray,
) -> Result(String, CodecError) {
  use <- bool.guard(
    when: version < 0 || version > 255,
    return: Error(InvalidVersion(version)),
  )
  use _ <- result.try(check_byte_alignment(payload))
  let versioned = bit_array.append(<<version:int>>, payload)
  let checksum = base58check_compute_checksum(versioned)
  let full = bit_array.append(versioned, checksum)
  Ok(bignum_encode(full, alphabet_new(base58check_symbols, CaseSensitive)))
}

// Decode a Base58Check string, verifying the checksum.
// Returns the version byte and payload on success.
fn base58check_decode(input: String) -> Result(Base58CheckDecoded, CodecError) {
  use bytes <- result.try(bignum_decode(
    input,
    alphabet_new(base58check_symbols, CaseSensitive),
  ))
  let length = bit_array.byte_size(bytes)
  let payload_length = length - 5
  case bytes {
    <<version, payload:bytes-size(payload_length), checksum:bytes-size(4)>> -> {
      let expected = base58check_compute_checksum(<<version, payload:bits>>)
      case checksum == expected {
        True -> Ok(Base58CheckDecoded(version:, payload:))
        False -> Error(InvalidChecksum)
      }
    }
    _ -> Error(InvalidLength(length))
  }
}

fn base58check_compute_checksum(data: BitArray) -> BitArray {
  let hash1 = sha256.hash(data)
  let hash2 = sha256.hash(hash1)
  case hash2 {
    <<a:8, b:8, c:8, d:8, _:bits>> -> <<a:int, b:int, c:int, d:int>>
    _ -> <<0, 0, 0, 0>>
  }
}

const base62_symbols =
  "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz"

// Encode a BitArray to Base62.
//
// Called after whole-byte validation.
fn base62_encode(data: BitArray) -> String {
  bignum_encode(data, alphabet_new(base62_symbols, CaseSensitive))
}

// Decode a Base62 string to a BitArray.
fn base62_decode(input: String) -> Result(BitArray, CodecError) {
  bignum_decode(input, alphabet_new(base62_symbols, CaseSensitive))
}

const base64_dq_dq_alphabet = [
  "あ", "い", "う", "え", "お", "か", "き", "く", "け", "こ", "さ", "し", "す", "せ", "そ", "た",
  "ち", "つ", "て", "と", "な", "に", "ぬ", "ね", "の", "は", "ひ", "ふ", "へ", "ほ", "ま", "み",
  "む", "め", "も", "や", "ゆ", "よ", "ら", "り", "る", "れ", "ろ", "わ", "が", "ぎ", "ぐ", "げ",
  "ご", "ざ", "じ", "ず", "ぜ", "ぞ", "だ", "ぢ", "づ", "で", "ど", "ば", "び", "ぶ", "べ", "ぼ",
]

const base64_dq_dq_pad = "・"

// Encode a BitArray to Base64 DQ (hiragana).
//
// Called after whole-byte validation.
fn base64_dq_encode(data: BitArray) -> String {
  base64_dq_encode_chunks(data, [])
  |> list.reverse
  |> string.join("")
}

fn base64_dq_encode_chunks(data: BitArray, acc: List(String)) -> List(String) {
  case data {
    <<a:6, b:6, c:6, d:6, rest:bits>> ->
      base64_dq_encode_chunks(rest, [
        base64_dq_dq_char_at(d),
        base64_dq_dq_char_at(c),
        base64_dq_dq_char_at(b),
        base64_dq_dq_char_at(a),
        ..acc
      ])
    <<a:6, b:6, c:4>> -> [
      base64_dq_dq_pad,
      base64_dq_dq_char_at(c * 4),
      base64_dq_dq_char_at(b),
      base64_dq_dq_char_at(a),
      ..acc
    ]
    <<a:6, b:2>> -> [
      base64_dq_dq_pad,
      base64_dq_dq_pad,
      base64_dq_dq_char_at(b * 16),
      base64_dq_dq_char_at(a),
      ..acc
    ]
    _ -> acc
  }
}

// Decode a Base64 DQ (hiragana) string to a BitArray.
//
// Non-alphabet graphemes (whitespace, ASCII, mismatched kana, etc.)
// are rejected with `InvalidCharacter` carrying the offending
// grapheme and its position. The alphabet check runs before the
// length check so the caller does not see a misleading
// `InvalidLength` when the real fault is an out-of-alphabet
// grapheme.
fn base64_dq_decode(input: String) -> Result(BitArray, CodecError) {
  use symbols <- result.try(base64_dq_parse(string.to_graphemes(input), 0, []))
  let length = list.length(symbols)
  use <- bool.guard(when: length % 4 != 0, return: Error(InvalidLength(length)))
  base64_dq_decode_symbols(symbols, [], 0, length)
}

fn base64_dq_finish(chunks: List(BitArray)) -> BitArray {
  bit_array.concat(list.reverse(chunks))
}

fn base64_dq_dq_char_at(index: Int) -> String {
  case list.drop(base64_dq_dq_alphabet, index) {
    [c, ..] -> c
    [] -> ""
  }
}

fn base64_dq_dq_value_of(c: String) -> Result(Int, Nil) {
  base64_dq_find_index(base64_dq_dq_alphabet, c, 0)
}

fn base64_dq_find_index(
  haystack: List(String),
  needle: String,
  idx: Int,
) -> Result(Int, Nil) {
  case haystack {
    [] -> Error(Nil)
    [h, ..rest] ->
      case h == needle {
        True -> Ok(idx)
        False -> base64_dq_find_index(rest, needle, idx + 1)
      }
  }
}

const base64_nopadding_symbols =
  "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"

// Encode a BitArray to Base64 without padding.
fn base64_nopadding_encode(data: BitArray) -> String {
  bit_array.base64_encode(data, False)
}

// Decode a Base64 string (without padding) to a BitArray.
// Length % 4 must be 0, 2, or 3 (never 1).
// Padding characters (=) and any non-alphabet byte (whitespace,
// CR/LF, punctuation) are rejected with `InvalidCharacter` carrying
// the offending byte and its position. The alphabet check runs
// before the length check so a whitespace byte does not surface as
// a misleading `InvalidLength`.
fn base64_nopadding_decode(input: String) -> Result(BitArray, CodecError) {
  bitgroup_decode_unpadded(
    input,
    6,
    alphabet_new(base64_nopadding_symbols, CaseSensitive),
  )
}

const base64_standard_symbols =
  "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"

// Encode a BitArray to standard Base64 with padding.
//
// Called after whole-byte validation.
fn base64_standard_encode(data: BitArray) -> String {
  bit_array.base64_encode(data, True)
}

// Decode a standard Base64 string to a BitArray.
// Per RFC 4648 section 3.3, non-alphabet characters (including
// whitespace, CR/LF, and other punctuation) are rejected. The
// alphabet check runs before the length check so the caller sees
// `InvalidCharacter` (with the offending byte and its position)
// rather than a misleading `InvalidLength` whenever the real fault
// is an out-of-alphabet byte.
fn base64_standard_decode(input: String) -> Result(BitArray, CodecError) {
  bitgroup_decode_base64_padded(
    input,
    alphabet_new(base64_standard_symbols, CaseSensitive),
  )
}

// Decode `input` and additionally reject non-canonical encodings
// per RFC 4648 §3.5: the trailing pad bits in a 1- or 2-byte final
// block must be zero. Useful for signature verification and
// content-addressable storage, where the wire encoding's uniqueness
// is part of the contract.
//
// Returns `Error(NonCanonical)` when the input decodes to bytes
// whose canonical re-encoding differs from the original input.
// Other failure modes (`InvalidCharacter`, `InvalidLength`) are
// surfaced unchanged from `decode/1`.
fn base64_standard_decode_strict(
  input: String,
) -> Result(BitArray, CodecError) {
  case base64_standard_decode(input) {
    Error(e) -> Error(e)
    Ok(bytes) ->
      case base64_standard_encode(bytes) == input {
        True -> Ok(bytes)
        False -> Error(NonCanonical)
      }
  }
}

const base64_urlsafe_symbols =
  "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-_"

// Encode a BitArray to URL-safe Base64 with padding.
//
// Called after whole-byte validation.
fn base64_urlsafe_encode(data: BitArray) -> String {
  bit_array.base64_url_encode(data, True)
}

// Decode a URL-safe Base64 string to a BitArray.
// Per RFC 4648 section 3.3, non-alphabet characters (including
// whitespace, CR/LF, and other punctuation) are rejected. The
// alphabet check runs before the length check so the caller sees
// `InvalidCharacter` rather than `InvalidLength` whenever the real
// fault is an out-of-alphabet byte.
fn base64_urlsafe_decode(input: String) -> Result(BitArray, CodecError) {
  bitgroup_decode_base64_padded(
    input,
    alphabet_new(base64_urlsafe_symbols, CaseSensitive),
  )
}

const base64_urlsafe_nopadding_symbols =
  "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-_"

// Encode a BitArray to URL-safe Base64 without padding.
fn base64_urlsafe_nopadding_encode(data: BitArray) -> String {
  bit_array.base64_url_encode(data, False)
}

// Decode a URL-safe Base64 string without padding to a BitArray.
// Length % 4 must be 0, 2, or 3 (never 1).
// Padding characters (=) are rejected.
fn base64_urlsafe_nopadding_decode(
  input: String,
) -> Result(BitArray, CodecError) {
  bitgroup_decode_unpadded(
    input,
    6,
    alphabet_new(base64_urlsafe_nopadding_symbols, CaseSensitive),
  )
}

const base8_symbols = "01234567"

// Encode a BitArray to an octal string.
//
// Called after whole-byte validation.
fn base8_encode(data: BitArray) -> String {
  bignum_encode(data, alphabet_new(base8_symbols, CaseSensitive))
}

// Decode an octal string to a BitArray.
fn base8_decode(input: String) -> Result(BitArray, CodecError) {
  bignum_decode(input, alphabet_new(base8_symbols, CaseSensitive))
}

fn base91_base91() -> Alphabet {
  alphabet_new(
    "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789!#$%&()*+,./:;<=>?@[]^_`{|}~\"",
    CaseSensitive,
  )
}

// Encode a BitArray to Base91.
//
// Called after whole-byte validation.
fn base91_encode(data: BitArray) -> String {
  base91_encode_loop(data, base91_base91(), 0, 0, [])
}

fn base91_encode_loop(
  data: BitArray,
  alphabet: Alphabet,
  queue: Int,
  queued: Int,
  acc: List(Int),
) -> String {
  case data {
    <<byte, rest:bytes>> -> {
      let queue = int.bitwise_or(queue, int.bitwise_shift_left(byte, queued))
      let queued = queued + 8
      case queued > 13 {
        True -> {
          let #(value, used) = base91_take_value(queue)
          base91_encode_loop(
            rest,
            alphabet,
            int.bitwise_shift_right(queue, used),
            queued - used,
            [
              alphabet_symbol(alphabet, value / 91),
              alphabet_symbol(alphabet, value % 91),
              ..acc
            ],
          )
        }
        False -> base91_encode_loop(rest, alphabet, queue, queued, acc)
      }
    }
    _ -> {
      let acc = case queued > 0 {
        False -> acc
        True ->
          case queued > 7 || queue > 90 {
            True -> [
              alphabet_symbol(alphabet, queue / 91 % 91),
              alphabet_symbol(alphabet, queue % 91),
              ..acc
            ]
            False -> [alphabet_symbol(alphabet, queue % 91), ..acc]
          }
      }
      alphabet_to_string(list.reverse(acc))
    }
  }
}

// Decode a Base91 string to a BitArray.
fn base91_decode(input: String) -> Result(BitArray, CodecError) {
  let bytes = bit_array.from_string(input)
  base91_decode_loop(
    Decoder(input: bytes, alphabet: base91_base91()),
    bytes,
    0,
    0,
    -1,
    0,
    0,
    [],
  )
}

type Decoder {
  Decoder(input: BitArray, alphabet: Alphabet)
}

fn base91_decode_loop(
  decoder: Decoder,
  rest: BitArray,
  offset: Int,
  position: Int,
  pending: Int,
  queue: Int,
  queued: Int,
  acc: List(BitArray),
) -> Result(BitArray, CodecError) {
  case rest {
    // The basE91 reference decoder ignores characters outside the
    // alphabet; this one only skips ASCII whitespace, so wrapped output
    // decodes. CR LF counts as one position, like one character.
    <<13, 10, rest:bytes>> ->
      base91_decode_loop(
        decoder,
        rest,
        offset + 2,
        position + 1,
        pending,
        queue,
        queued,
        acc,
      )
    <<byte, rest:bytes>>
      if byte == 32 || byte == 9 || byte == 10 || byte == 13
    ->
      base91_decode_loop(
        decoder,
        rest,
        offset + 1,
        position + 1,
        pending,
        queue,
        queued,
        acc,
      )
    <<byte, rest:bytes>> ->
      case alphabet_lookup(decoder.alphabet, byte) {
        Value(digit) if pending == -1 ->
          base91_decode_loop(
            decoder,
            rest,
            offset + 1,
            position + 1,
            digit,
            queue,
            queued,
            acc,
          )
        Value(digit) -> {
          let value = pending + digit * 91
          let used = case int.bitwise_and(value, 8191) > 88 {
            True -> 13
            False -> 14
          }
          let queue =
            int.bitwise_or(queue, int.bitwise_shift_left(value, queued))
          let #(queue, queued, acc) =
            base91_flush_bytes(queue, queued + used, acc)
          base91_decode_loop(
            decoder,
            rest,
            offset + 1,
            position + 1,
            -1,
            queue,
            queued,
            acc,
          )
        }
        Ignored | Invalid ->
          Error(alphabet_invalid_character(
            decoder.alphabet,
            decoder.input,
            offset,
            position,
          ))
      }
    _ -> {
      // Flush one final byte from the remaining bits, as the C reference
      // does.
      let acc = base91_finish_pending(pending, queue, queued, acc)
      Ok(bit_array.concat(list.reverse(acc)))
    }
  }
}

fn base91_flush_bytes(
  queue: Int,
  queued: Int,
  acc: List(BitArray),
) -> #(Int, Int, List(BitArray)) {
  use <- bool.guard(when: queued < 8, return: #(queue, queued, acc))
  base91_flush_bytes(int.bitwise_shift_right(queue, 8), queued - 8, [
    <<{ int.bitwise_and(queue, 255) }>>,
    ..acc
  ])
}

const bech32_charset = "qpzry9x8gf2tvdw0s3jn54khce6mua7l"

const bech32_bech32_const = 1

const bech32_bech32m_const = 0x2bc830a3

// Encode byte data with Bech32 or Bech32m.
// variant: Bech32 (BIP 173) or Bech32m (BIP 350).
// hrp: human-readable part (e.g. `"bc"` for Bitcoin mainnet). Must be
//   all lowercase per BIP 173 — uppercase characters are rejected with
//   `Error(InvalidHrp("HRP must be lowercase"))` rather than silently
//   normalized, so the input is never quietly mutated. Lowercase the
//   value at the call site if you started from a mixed-case identifier.
// data: raw bytes (8-to-5 bit conversion is done internally). Input that
//   is not a whole number of bytes is rejected with
//   `Error(UnalignedInput(bit_size))`.
fn bech32_encode(
  variant: Bech32Variant,
  hrp: String,
  data: BitArray,
) -> Result(String, CodecError) {
  bech32_encode_variant(variant, hrp, data)
}

// Decode a Bech32 or Bech32m string, auto-detecting the variant.
// Per BIP 173: total length <= 90, HRP length 1..83.
fn bech32_decode(input: String) -> Result(Bech32Decoded, CodecError) {
  let total_length = string.length(input)
  use <- bool.guard(
    when: total_length > 90,
    return: Error(InvalidLength(total_length)),
  )
  use Nil <- result.try(bech32_validate_ascii(
    bit_array.from_string(input),
    DecodeSource(input, 0),
    0,
  ))
  let lower = string.lowercase(input)
  use <- bool.guard(
    when: input != lower && input != string.uppercase(input),
    return: Error(MixedCase),
  )
  // Split on the last separator, since the HRP may itself contain '1'.
  case list.reverse(string.split(lower, "1")) {
    [] | [_] -> Error(InvalidHrp("no separator '1' found"))
    [data_part, ..hrp_parts] -> {
      let hrp = hrp_parts |> list.reverse |> string.join("1")
      use Nil <- result.try(bech32_check_hrp(hrp))
      bech32_decode_data_part(
        hrp,
        data_part,
        DecodeSource(input, string.length(hrp) + 1),
      )
    }
  }
}

fn bech32_validate_ascii(
  input: BitArray,
  source: DecodeSource,
  offset: Int,
) -> Result(Nil, CodecError) {
  case input {
    <<byte, rest:bytes>> if byte < 128 ->
      bech32_validate_ascii(rest, source, offset + 1)
    <<>> -> Ok(Nil)
    _ -> Error(source_invalid_character(source, offset))
  }
}

fn bech32_check_hrp(hrp: String) -> Result(Nil, CodecError) {
  let length = string.length(hrp)
  use <- bool.guard(when: length < 1, return: Error(InvalidHrp("empty HRP")))
  use <- bool.guard(
    when: length > 83,
    return: Error(InvalidHrp("HRP too long")),
  )
  bech32_validate_hrp(hrp, 0)
}

fn bech32_validate_hrp(hrp: String, position: Int) -> Result(Nil, CodecError) {
  case string.pop_grapheme(hrp) {
    Error(Nil) -> Ok(Nil)
    Ok(#(character, rest)) -> {
      use _ <- result.try(bech32_check_hrp_character(character, position))
      bech32_validate_hrp(rest, position + 1)
    }
  }
}

fn bech32_encode_variant(
  variant: Bech32Variant,
  hrp: String,
  data: BitArray,
) -> Result(String, CodecError) {
  use <- bool.guard(
    when: hrp != string.lowercase(hrp),
    return: Error(InvalidHrp("HRP must be lowercase")),
  )
  use Nil <- result.try(bech32_check_hrp(hrp))
  use _ <- result.try(check_byte_alignment(data))
  let bits = bit_array.bit_size(data)
  let length = string.length(hrp) + 7 + { bits + 4 } / 5
  use <- bool.guard(when: length > 90, return: Error(InvalidLength(length)))
  let table = alphabet_new(bech32_charset, CaseSensitive)
  let payload = bitgroup_encode(data, 5, table, Unpadded)
  use values <- result.try(bech32_chars_to_values(
    bit_array.from_string(payload),
    table,
    [],
    0,
  ))
  let constant = case variant {
    Bech32 -> bech32_bech32_const
    Bech32m -> bech32_bech32m_const
  }
  let checksum = bech32_create_checksum(hrp, values, constant)
  Ok(hrp <> "1" <> payload <> bech32_values_to_chars(checksum, table))
}

fn bech32_decode_data_part(
  hrp: String,
  data_part: String,
  source: DecodeSource,
) -> Result(Bech32Decoded, CodecError) {
  let length = string.length(data_part)
  use <- bool.guard(when: length < 6, return: Error(InvalidLength(length)))
  let table = alphabet_new(bech32_charset, CaseSensitive)
  use values <- result.try(
    bech32_chars_to_values(bit_array.from_string(data_part), table, [], 0)
    |> result.map_error(fn(error) {
      case error {
        InvalidCharacter(_, offset) -> source_invalid_character(source, offset)
        other -> other
      }
    }),
  )
  let checksum = bech32_polymod(list.append(bech32_hrp_expand(hrp), values))
  let variant = case checksum {
    _ if checksum == bech32_bech32_const -> Ok(Bech32)
    _ if checksum == bech32_bech32m_const -> Ok(Bech32m)
    _ -> Error(InvalidChecksum)
  }
  use variant <- result.try(variant)
  let data_values = list.take(values, length - 6)
  let leftover = { length - 6 } * 5 % 8
  use <- bool.guard(
    when: leftover > 4,
    return: Error(InvalidLength(length - 6)),
  )
  let last = case list.last(data_values) {
    Ok(value) -> value
    Error(Nil) -> 0
  }
  use <- bool.guard(
    when: last % int.bitwise_shift_left(1, leftover) != 0,
    return: Error(NonZeroPadding),
  )
  use bytes <- result.map(bitgroup_decode_unpadded(
    bech32_values_to_chars(data_values, table),
    5,
    table,
  ))
  Bech32Decoded(hrp:, data: bytes, variant:)
}

fn bech32_chars_to_values(
  input: BitArray,
  table: Alphabet,
  values: List(Int),
  position: Int,
) -> Result(List(Int), CodecError) {
  case input {
    <<byte, rest:bytes>> ->
      case alphabet_lookup(table, byte) {
        Value(value) ->
          bech32_chars_to_values(rest, table, [value, ..values], position + 1)
        Invalid | Ignored ->
          Error(InvalidCharacter(alphabet_to_string([byte]), position))
      }
    _ -> Ok(list.reverse(values))
  }
}

fn bech32_values_to_chars(values: List(Int), table: Alphabet) -> String {
  values |> list.map(alphabet_symbol(table, _)) |> alphabet_to_string
}

fn bech32_polymod(values: List(Int)) -> Int {
  list.fold(values, 1, fn(checksum, value) {
    let head = int.bitwise_shift_right(checksum, 25)
    let checksum =
      int.bitwise_exclusive_or({ checksum % 33_554_432 } * 32, value)
    checksum
    |> bech32_xor_if(head, 0, 0x3b6a57b2)
    |> bech32_xor_if(head, 1, 0x26508e6d)
    |> bech32_xor_if(head, 2, 0x1ea119fa)
    |> bech32_xor_if(head, 3, 0x3d4233dd)
    |> bech32_xor_if(head, 4, 0x2a1462b3)
  })
}

fn bech32_xor_if(checksum: Int, head: Int, bit: Int, generator: Int) -> Int {
  case int.bitwise_and(int.bitwise_shift_right(head, bit), 1) {
    1 -> int.bitwise_exclusive_or(checksum, generator)
    _ -> checksum
  }
}

fn bech32_hrp_expand(hrp: String) -> List(Int) {
  let codes =
    hrp |> string.to_utf_codepoints |> list.map(string.utf_codepoint_to_int)
  let high = list.map(codes, fn(code) { code / 32 })
  let low = list.map(codes, fn(code) { code % 32 })
  list.append(high, [0, ..low])
}

fn bech32_create_checksum(
  hrp: String,
  data: List(Int),
  constant: Int,
) -> List(Int) {
  let values =
    list.append(bech32_hrp_expand(hrp), list.append(data, [0, 0, 0, 0, 0, 0]))
  let checksum = int.bitwise_exclusive_or(bech32_polymod(values), constant)
  list.map([25, 20, 15, 10, 5, 0], fn(shift) {
    int.bitwise_and(int.bitwise_shift_right(checksum, shift), 31)
  })
}

// Build a `Decoded` value. Package-internal; multibase decoders use
// this to tag their result. External callers receive a `Decoded`
// from `multibase.decode/1` and inspect it with `decoded_encoding`
// / `decoded_data`.
fn encoding_make_decoded(encoding: Encoding, data: BitArray) -> Decoded {
  Decoded(encoding: encoding, data: data)
}

fn encoding_base8() -> Encoding {
  Base8
}

// ---------------------------------------------------------------------------
// Integer codec dispatch tags.
//
// `Encoding` is opaque so callers cannot pattern-match its variants
// from outside this module. The `intid` facade needs to branch on
// the variant to dispatch `encode_int` / `decode_int` to the right
// per-base helper without re-implementing the integer ↔ bytes shim
// in this module (which would introduce an import cycle with the
// per-base modules). `IntCodec` is the non-opaque tag the facade
// reads via `int_codec/1`. The variants enumerate exactly the
// encodings that `yabase/intid` currently supports; everything else
// surfaces as `IntCodecUnsupported(name)` so the facade can return
// `UnsupportedForInt(name)` without losing the encoding identity.
// ---------------------------------------------------------------------------

// A tag describing which integer codec, if any, `yabase/intid`
// should dispatch to for a given `Encoding`. Used by the
// `intid.encode_int` / `intid.decode_int` facade; not interesting
// for callers that pick the codec at compile time and reach for
// the per-base `encode_int_*` / `decode_int_*` helpers directly.
type IntCodec {
  IntBase10
  IntBase16
  IntBase32Rfc4648
  IntBase32Crockford
  IntBase32CrockfordCheck
  IntBase36
  IntBase58Bitcoin
  IntBase58Flickr
  IntBase58Check(version: Int)
  IntBase62
  /// The `Encoding` has no integer codec wired up; the carried
  /// name is the encoding's display identity for use in
  /// `UnsupportedForInt(name)`.
  IntCodecUnsupported(name: String)
}

// Map an `Encoding` to the tag describing how `yabase/intid` should
// handle it. Internal to the package — exposed because `intid` lives
// in a separate module but needs to branch on the opaque variant.
fn encoding_int_codec(encoding: Encoding) -> IntCodec {
  case encoding {
    Base16Lowercase -> IntCodecUnsupported("Base16Lowercase")
    Base10 -> IntBase10
    Base16 -> IntBase16
    Base32Rfc4648 -> IntBase32Rfc4648
    Base32Crockford -> IntBase32Crockford
    Base32CrockfordCheck -> IntBase32CrockfordCheck
    Base36 -> IntBase36
    Base58Bitcoin -> IntBase58Bitcoin
    Base58Flickr -> IntBase58Flickr
    Base58Check(version) -> IntBase58Check(version)
    Base62 -> IntBase62
    Base2 -> IntCodecUnsupported("Base2")
    Base8 -> IntCodecUnsupported("Base8")
    Base32Hex -> IntCodecUnsupported("Base32(Hex)")
    Base32Clockwork -> IntCodecUnsupported("Base32(Clockwork)")
    Zbase32 -> IntCodecUnsupported("Base32(ZBase32)")
    Base45 -> IntCodecUnsupported("Base45")
    Base64 -> IntCodecUnsupported("Base64(Standard)")
    Base64UrlSafe -> IntCodecUnsupported("Base64(UrlSafe)")
    Base64NoPadding -> IntCodecUnsupported("Base64(NoPadding)")
    Base64UrlSafeNoPadding -> IntCodecUnsupported("Base64(UrlSafeNoPadding)")
    Base64Dq -> IntCodecUnsupported("Base64(DQ)")
    Ascii85 -> IntCodecUnsupported("Base85(Btoa)")
    AdobeAscii85 -> IntCodecUnsupported("Base85(Adobe)")
    Rfc1924Base85 -> IntCodecUnsupported("Base85(Rfc1924)")
    Z85 -> IntCodecUnsupported("Base85(Z85)")
    Base91 -> IntCodecUnsupported("Base91")
    Bech32Encoding(_, _) -> IntCodecUnsupported("Bech32")
  }
}

// ---------------------------------------------------------------------------
// Dispatch.
// ---------------------------------------------------------------------------

// Encode data using the specified encoding.
fn encoding_encode(
  encoding: Encoding,
  data: BitArray,
) -> Result(String, CodecError) {
  case encoding {
    Base16Lowercase -> Ok(base16_encode_lowercase(data))
    Base2 -> Ok(base2_encode(data))
    Base8 -> Ok(base8_encode(data))
    Base10 -> Ok(base10_encode(data))
    Base16 -> Ok(base16_encode(data))
    Base32Rfc4648 -> Ok(base32_rfc4648_encode(data))
    Base32Hex -> Ok(base32_hex_encode(data))
    Base32Crockford -> Ok(base32_crockford_encode(data))
    Base32CrockfordCheck -> Ok(base32_crockford_encode_check(data))
    Base32Clockwork -> Ok(base32_clockwork_encode(data))
    Zbase32 -> Ok(base32_zbase32_encode(data))
    Base36 -> Ok(base36_encode(data))
    Base45 -> Ok(base45_encode(data))
    Base58Bitcoin -> Ok(base58_bitcoin_encode(data))
    Base58Flickr -> Ok(base58_flickr_encode(data))
    Base58Check(version) -> base58check_encode(version, data)
    Base62 -> Ok(base62_encode(data))
    Base64 -> Ok(base64_standard_encode(data))
    Base64UrlSafe -> Ok(base64_urlsafe_encode(data))
    Base64NoPadding -> Ok(base64_nopadding_encode(data))
    Base64UrlSafeNoPadding -> Ok(base64_urlsafe_nopadding_encode(data))
    Base64Dq -> Ok(base64_dq_encode(data))
    Ascii85 -> Ok(ascii85_encode(data))
    AdobeAscii85 -> Ok(adobe_ascii85_encode(data))
    Rfc1924Base85 -> rfc1924_base85_encode(data)
    Z85 -> z85_encode(data)
    Base91 -> Ok(base91_encode(data))
    Bech32Encoding(hrp, variant) -> bech32_encode(variant, hrp, data)
  }
}

// Decode a string using the specified encoding.
fn encoding_decode_as(
  encoding: Encoding,
  value: String,
) -> Result(BitArray, CodecError) {
  case encoding {
    Base16Lowercase -> base16_decode(value)
    Base2 -> base2_decode(value)
    Base8 -> base8_decode(value)
    Base10 -> base10_decode(value)
    Base16 -> base16_decode(value)
    Base32Rfc4648 -> base32_rfc4648_decode(value)
    Base32Hex -> base32_hex_decode(value)
    Base32Crockford -> base32_crockford_decode(value)
    Base32CrockfordCheck -> base32_crockford_decode_check(value)
    Base32Clockwork -> base32_clockwork_decode(value)
    Zbase32 -> base32_zbase32_decode(value)
    Base36 -> base36_decode(value)
    Base45 -> base45_decode(value)
    Base58Bitcoin -> base58_bitcoin_decode(value)
    Base58Flickr -> base58_flickr_decode(value)
    Base58Check(version) ->
      encoding_decode_base58check_with_version(value, version)
    Base62 -> base62_decode(value)
    Base64 -> base64_standard_decode(value)
    Base64UrlSafe -> base64_urlsafe_decode(value)
    Base64NoPadding -> base64_nopadding_decode(value)
    Base64UrlSafeNoPadding -> base64_urlsafe_nopadding_decode(value)
    Base64Dq -> base64_dq_decode(value)
    Ascii85 -> ascii85_decode(value)
    AdobeAscii85 -> adobe_ascii85_decode(value)
    Rfc1924Base85 -> rfc1924_base85_decode(value)
    Z85 -> z85_decode(value)
    Base91 -> base91_decode(value)
    Bech32Encoding(hrp, variant) ->
      encoding_decode_bech32_with_metadata(value, hrp, variant)
  }
}

// Decode a Base58Check string and reject the result if the embedded
// version byte does not match the version declared in the
// `Encoding` value.
fn encoding_decode_base58check_with_version(
  value: String,
  expected_version: Int,
) -> Result(BitArray, CodecError) {
  use decoded <- result.try(base58check_decode(value))
  use _ <- result.try(check_version(expected_version))
  case decoded.version == expected_version {
    True -> Ok(decoded.payload)
    False -> Error(UnexpectedVersion(expected_version, decoded.version))
  }
}

// Decode a Bech32 string and reject the result if the embedded HRP
// or variant does not match what the `Encoding` value declared.
fn encoding_decode_bech32_with_metadata(
  value: String,
  expected_hrp: String,
  expected_variant: Bech32Variant,
) -> Result(BitArray, CodecError) {
  use decoded <- result.try(bech32_decode(value))
  use _ <- result.try(bech32_check_hrp(expected_hrp))
  use <- bool.guard(
    when: decoded.hrp != expected_hrp,
    return: Error(UnexpectedHrp(expected_hrp, decoded.hrp)),
  )
  use <- bool.guard(
    when: decoded.variant != expected_variant,
    return: Error(UnexpectedBech32Variant(expected_variant, decoded.variant)),
  )
  Ok(decoded.data)
}

// ---------------------------------------------------------------------------
// Multibase metadata.
// ---------------------------------------------------------------------------

// Map an `Encoding` to its official multibase prefix character.
fn encoding_multibase_prefix(encoding: Encoding) -> Result(String, Nil) {
  case encoding {
    Base16Lowercase -> Ok("f")
    Base2 -> Ok("0")
    Base8 -> Ok("7")
    Base10 -> Ok("9")
    Base16 -> Ok("f")
    Base32Rfc4648 -> Ok("c")
    Base32Hex -> Ok("t")
    Base32Crockford -> Error(Nil)
    Base32CrockfordCheck -> Error(Nil)
    Base32Clockwork -> Error(Nil)
    Zbase32 -> Ok("h")
    Base36 -> Ok("k")
    Base45 -> Ok("R")
    Base58Bitcoin -> Ok("z")
    Base58Flickr -> Ok("Z")
    Base62 -> Error(Nil)
    Base64 -> Ok("M")
    Base64UrlSafe -> Ok("U")
    Base64NoPadding -> Ok("m")
    Base64UrlSafeNoPadding -> Ok("u")
    Base64Dq -> Error(Nil)
    Ascii85 -> Error(Nil)
    AdobeAscii85 -> Error(Nil)
    Rfc1924Base85 -> Error(Nil)
    Z85 -> Error(Nil)
    Base91 -> Error(Nil)
    // Checksum-bearing encodings carry per-instance metadata (version
    // / HRP) that has no place in the prefix-only multibase scheme,
    // so they have no assigned multibase prefix.
    Base58Check(_) -> Error(Nil)
    Bech32Encoding(_, _) -> Error(Nil)
  }
}

// Map a multibase prefix character to its `Encoding`.
fn encoding_from_multibase_prefix_impl(
  prefix: String,
) -> Result(Encoding, Nil) {
  case prefix {
    "0" -> Ok(Base2)
    "7" -> Ok(Base8)
    "9" -> Ok(Base10)
    "f" | "F" -> Ok(Base16)
    "c" | "C" -> Ok(Base32Rfc4648)
    "b" | "B" -> Ok(Base32Rfc4648)
    "t" | "T" -> Ok(Base32Hex)
    "v" | "V" -> Ok(Base32Hex)
    "k" | "K" -> Ok(Base36)
    "R" -> Ok(Base45)
    "z" -> Ok(Base58Bitcoin)
    "Z" -> Ok(Base58Flickr)
    "h" -> Ok(Zbase32)
    "M" -> Ok(Base64)
    "m" -> Ok(Base64NoPadding)
    "U" -> Ok(Base64UrlSafe)
    "u" -> Ok(Base64UrlSafeNoPadding)
    _ -> Error(Nil)
  }
}

// Human-readable name for an `Encoding`.
fn encoding_multibase_name(encoding: Encoding) -> String {
  case encoding {
    Base16Lowercase -> "base16lower"
    Base2 -> "base2"
    Base8 -> "base8"
    Base10 -> "base10"
    Base16 -> "base16"
    Base32Rfc4648 -> "base32pad"
    Base32Hex -> "base32hexpad"
    Base32Crockford -> "base32crockford"
    Base32CrockfordCheck -> "base32crockford-check"
    Base32Clockwork -> "base32clockwork"
    Zbase32 -> "base32z"
    Base36 -> "base36"
    Base45 -> "base45"
    Base58Bitcoin -> "base58btc"
    Base58Flickr -> "base58flickr"
    Base62 -> "base62"
    Base64 -> "base64pad"
    Base64UrlSafe -> "base64urlpad"
    Base64NoPadding -> "base64"
    Base64UrlSafeNoPadding -> "base64url"
    Base64Dq -> "base64dq"
    Ascii85 -> "ascii85"
    AdobeAscii85 -> "adobe-ascii85"
    Rfc1924Base85 -> "rfc1924-base85"
    Z85 -> "z85"
    Base91 -> "base91"
    Base58Check(_) -> "base58check"
    Bech32Encoding(_, Bech32) -> "bech32"
    Bech32Encoding(_, Bech32m) -> "bech32m"
  }
}

// Lowercase the dispatcher's output for encodings whose multibase
// prefix pins a lowercase payload: `f` (Base16), `c` (Base32 RFC 4648,
// padded) and `t` (Base32 Hex, padded).
fn encoding_normalise_for_multibase_prefix(
  encoding: Encoding,
  encoded: String,
) -> String {
  case encoding {
    Base16Lowercase -> string.lowercase(encoded)
    Base16 | Base32Rfc4648 | Base32Hex -> string.lowercase(encoded)
    Base2
    | Base8
    | Base10
    | Base32Crockford
    | Base32CrockfordCheck
    | Base32Clockwork
    | Zbase32
    | Base36
    | Base45
    | Base58Bitcoin
    | Base58Flickr
    | Base58Check(_)
    | Base62
    | Base64
    | Base64UrlSafe
    | Base64NoPadding
    | Base64UrlSafeNoPadding
    | Base64Dq
    | Ascii85
    | AdobeAscii85
    | Rfc1924Base85
    | Z85
    | Base91
    | Bech32Encoding(_, _) -> encoded
  }
}

// Reject a `BitArray` whose total bit length is not a multiple of 8.
//
// yabase encoders walk their input one byte at a time. A sub-byte
// trailing segment (`<<1:size(1)>>`, `<<0xFF, 0x80, 1:size(3)>>`,
// …) would otherwise be silently dropped by the byte-walker
// pattern, producing a string that decodes to a strictly shorter
// `BitArray` than the caller supplied — silent data loss. Every
// `encode` function calls this at the boundary so the truncation
// becomes a loud crash instead.
//
// Crashing rather than returning a `Result` keeps the public
// `encode` shape per-codec compatible with v0.14.x callers
// (`fn(BitArray) -> String`); a sub-byte input has always been
// outside the contract, so there is no caller that previously
// "worked" with one. RFC 4648-conformant encoders never receive
// sub-byte input in practice, so the guard is a safety net for
// programmer-error inputs only.
fn check_byte_alignment(input: BitArray) -> Result(Nil, CodecError) {
  // The stdlib 0.44 JavaScript bit_size getter throws for unaligned input.
  // A whole-byte pattern checks alignment without calling that getter.
  case input {
    <<_:bytes>> -> Ok(Nil)
    _ -> Error(UnalignedInput(count_input_bits(input, 0)))
  }
}

// Encode data with a multibase prefix.
fn multibase_encode_with_prefix(
  encoding: Encoding,
  data: BitArray,
) -> Result(String, CodecError) {
  case encoding_multibase_prefix(encoding) {
    Error(Nil) ->
      Error(UnsupportedMultibaseEncoding(encoding_multibase_name(encoding)))
    Ok(prefix) ->
      multibase_encode_payload(encoding, data)
      |> result.map(fn(encoded) {
        prefix <> encoding_normalise_for_multibase_prefix(encoding, encoded)
      })
  }
}

// Multibase base8 (prefix "7") writes 3-bit groups like RFC 4648 does for
// base32, while `yabase/base8` treats its input as one number. Only the
// multibase path uses the bit-group form.
fn multibase_encode_payload(
  encoding: Encoding,
  data: BitArray,
) -> Result(String, CodecError) {
  use _ <- result.try(check_byte_alignment(data))
  case encoding == encoding_base8() {
    True -> {
      Ok(bitgroup_encode(data, 3, multibase_octal(), Unpadded))
    }
    False -> encoding_encode(encoding, data)
  }
}

fn multibase_decode_payload(
  encoding: Encoding,
  payload: String,
) -> Result(BitArray, CodecError) {
  case encoding == encoding_base8() {
    True -> bitgroup_decode_unpadded(payload, 3, multibase_octal())
    False -> encoding_decode_as(encoding, payload)
  }
}

fn multibase_octal() -> Alphabet {
  alphabet_new("01234567", CaseSensitive)
}

// Decode a multibase-prefixed string, auto-detecting the encoding.
fn multibase_decode(value: String) -> Result(Decoded, CodecError) {
  case string.pop_grapheme(value) {
    Error(Nil) -> Error(UnsupportedPrefix(""))
    Ok(#(prefix, rest)) ->
      case encoding_from_multibase_prefix_impl(prefix) {
        Error(Nil) -> Error(UnsupportedPrefix(prefix))
        Ok(encoding) ->
          multibase_decode_payload(encoding, rest)
          |> result.map_error(fn(error) {
            case error {
              // Accepted prefixes are exactly one ASCII grapheme.
              InvalidCharacter(character, position) ->
                InvalidCharacter(character, position + 1)
              other -> other
            }
          })
          |> result.map(fn(data) { encoding_make_decoded(encoding, data) })
      }
  }
}

// How a decoder treats letter case.
type Folding {
  /// Only the symbols themselves are accepted.
  CaseSensitive
  /// Both cases are accepted; a rejected letter is reported in upper case.
  FoldToUpper
  /// Both cases are accepted; a rejected letter is reported in lower case.
  FoldToLower
}

type Alphabet {
  Alphabet(symbols: BitArray, values: BitArray, folding: Folding)
}

// Marks a byte that is not part of the alphabet.
const alphabet_invalid = 255

// Marks a byte the decoder drops without counting it as a character.
const alphabet_ignored = 254

// Build an alphabet whose symbol for value `i` is the `i`-th byte of
// `symbols`.
fn alphabet_new(symbols: String, folding: Folding) -> Alphabet {
  alphabet_with_extras(symbols:, folding:, aliases: [], ignore: "")
}

// Like `new`, but `aliases` adds extra accepted characters for a value and
// `ignore` lists characters the decoder skips without counting them.
fn alphabet_with_extras(
  symbols symbols: String,
  folding folding: Folding,
  aliases aliases: List(#(String, Int)),
  ignore ignore: String,
) -> Alphabet {
  let symbol_bytes = bit_array.from_string(symbols)
  let entries =
    list.index_map(string.to_graphemes(symbols), fn(alphabet_symbol, value) {
      #(alphabet_symbol, value)
    })
    |> list.append(aliases)
    |> list.flat_map(fn(entry) {
      let #(alphabet_symbol, value) = entry
      case folding {
        CaseSensitive -> [#(alphabet_symbol, value)]
        FoldToUpper | FoldToLower -> [
          #(string.uppercase(alphabet_symbol), value),
          #(string.lowercase(alphabet_symbol), value),
        ]
      }
    })
    |> list.append(
      list.map(string.to_graphemes(ignore), fn(alphabet_symbol) {
        #(alphabet_symbol, alphabet_ignored)
      }),
    )
  let table =
    list.fold(entries, dict.new(), fn(table, entry) {
      case bit_array.from_string(entry.0) {
        <<byte>> -> dict.insert(table, byte, entry.1)
        _ -> table
      }
    })
  Alphabet(
    symbols: symbol_bytes,
    values: alphabet_build_values(table, 255, []),
    folding: folding,
  )
}

fn alphabet_build_values(
  table: Dict(Int, Int),
  byte: Int,
  acc: List(BitArray),
) -> BitArray {
  case byte < 0 {
    True -> bit_array.concat(acc)
    False -> {
      let value = case dict.get(table, byte) {
        Ok(value) -> value
        Error(Nil) -> alphabet_invalid
      }
      alphabet_build_values(table, byte - 1, [<<value>>, ..acc])
    }
  }
}

// Number of symbols, which is the radix of the alphabet.
fn alphabet_size(alphabet: Alphabet) -> Int {
  bit_array.byte_size(alphabet.symbols)
}

// The symbol byte for `value`. `value` must be below `size(alphabet)`.
fn alphabet_symbol(alphabet: Alphabet, value: Int) -> Int {
  case alphabet.symbols {
    <<_:bytes-size(value), byte, _:bits>> -> byte
    // Callers only pass values below the radix.
    _ -> 0
  }
}

// What a byte means to the decoder.
type Lookup {
  Value(Int)
  Ignored
  Invalid
}

// Look up one input byte.
fn alphabet_lookup(alphabet: Alphabet, byte: Int) -> Lookup {
  case alphabet.values {
    <<_:bytes-size(byte), value, _:bits>> ->
      case value {
        _ if value == alphabet_invalid -> Invalid
        _ if value == alphabet_ignored -> Ignored
        _ -> Value(value)
      }
    _ -> Invalid
  }
}

// The error for the character that starts at byte `offset` of `input`,
// which is character number `position`. Every byte before `offset` must be
// ASCII, so `offset` starts a UTF-8 sequence.
fn alphabet_invalid_character(
  _alphabet: Alphabet,
  input: BitArray,
  offset: Int,
  _position: Int,
) -> CodecError {
  // Codec input is UTF-8 even when a byte scanner rejects part of a grapheme.
  let original = source_text(input)
  source_invalid_character(DecodeSource(original, 0), offset)
}

// Join symbol bytes, given most significant first, into a string.
fn alphabet_to_string(symbols: List(Int)) -> String {
  symbols
  |> list.map(fn(byte) { <<byte>> })
  |> alphabet_chunks_to_string
}

// Join chunks of symbol bytes into a string. The chunks hold only
// alphabet symbols, which are ASCII.
fn alphabet_chunks_to_string(chunks: List(BitArray)) -> String {
  case bit_array.to_string(bit_array.concat(chunks)) {
    Ok(text) -> text
    Error(Nil) -> ""
  }
}

// Characters (graphemes) in `input`, whose bytes are `bytes`. ASCII
// without CR has one character per byte, so only other input needs the
// slower `string.length`.
fn alphabet_character_count(input: String, bytes: BitArray) -> Int {
  case alphabet_plain_ascii(bytes) {
    True -> bit_array.byte_size(bytes)
    False -> string.length(input)
  }
}

fn alphabet_plain_ascii(bytes: BitArray) -> Bool {
  case bytes {
    <<byte, rest:bytes>> if byte < 128 && byte != 13 ->
      alphabet_plain_ascii(rest)
    <<_, _:bytes>> -> False
    _ -> True
  }
}

const base85_max_u32 = 4_294_967_295

const base85_ascii85_symbols =
  "!\"#$%&'()*+,-./0123456789:;<=>?@ABCDEFGHIJKLMNOPQRSTUVWXYZ[\\]^_`abcdefghijklmnopqrstu"

// The Ascii85 alphabet: the characters `!` (33) to `u` (117).
fn base85_ascii85_alphabet() -> Alphabet {
  alphabet_new(base85_ascii85_symbols, CaseSensitive)
}

// Which group shortcuts an encoder emits and a decoder accepts.
type Shortcuts {
  /// No shortcuts (Z85, RFC 1924).
  NoShortcuts
  /// `z` for four zero bytes (Adobe).
  ZeroShortcut
  /// `z` for four zero bytes and `y` for four spaces (btoa).
  ZeroAndSpaceShortcuts
}

// Encode `data`. A final group of 1 to 3 bytes is padded with zeros and
// written as one more character than it has bytes.
fn base85_encode(
  data: BitArray,
  alphabet: Alphabet,
  shortcuts: Shortcuts,
) -> String {
  base85_encode_loop(data, alphabet, shortcuts, [])
}

fn base85_encode_loop(
  data: BitArray,
  alphabet: Alphabet,
  shortcuts: Shortcuts,
  acc: List(BitArray),
) -> String {
  case data, shortcuts {
    <<0:32, rest:bytes>>, ZeroShortcut
    | <<0:32, rest:bytes>>, ZeroAndSpaceShortcuts
    -> base85_encode_loop(rest, alphabet, shortcuts, [<<"z":utf8>>, ..acc])
    <<0x20202020:32, rest:bytes>>, ZeroAndSpaceShortcuts ->
      base85_encode_loop(rest, alphabet, shortcuts, [<<"y":utf8>>, ..acc])
    <<value:32, rest:bytes>>, _ ->
      base85_encode_loop(rest, alphabet, shortcuts, [
        base85_group_symbols(value, alphabet, 5),
        ..acc
      ])
    <<>>, _ -> alphabet_chunks_to_string(list.reverse(acc))
    _, _ -> {
      let count = bit_array.byte_size(data)
      let value = base85_tail_value(data, 0, 4 - count)
      alphabet_chunks_to_string(
        list.reverse([base85_group_symbols(value, alphabet, count + 1), ..acc]),
      )
    }
  }
}

// The value of a final group of 1 to 3 bytes padded with `padding` zero
// bytes.
fn base85_tail_value(data: BitArray, value: Int, padding: Int) -> Int {
  case data, padding {
    <<byte, rest:bytes>>, _ ->
      base85_tail_value(rest, value * 256 + byte, padding)
    _, 0 -> value
    _, _ -> base85_tail_value(data, value * 256, padding - 1)
  }
}

// The first `count` of the five digits of `value`, as symbol bytes.
fn base85_group_symbols(
  value: Int,
  alphabet: Alphabet,
  count: Int,
) -> BitArray {
  let digits = [
    value / 52_200_625 % 85,
    value / 614_125 % 85,
    value / 7225 % 85,
    value / 85 % 85,
    value % 85,
  ]
  list.take(digits, count)
  |> list.map(fn(digit) { <<{ alphabet_symbol(alphabet, digit) }>> })
  |> bit_array.concat
}

// Decode Z85 or RFC 1924 text: no whitespace, no shortcuts, and the length
// must be a multiple of five characters. The length is checked first.
fn base85_decode_groups(
  input: String,
  alphabet: Alphabet,
) -> Result(BitArray, CodecError) {
  let bytes = bit_array.from_string(input)
  let length = alphabet_character_count(input, bytes)
  use <- bool.guard(when: length % 5 != 0, return: Error(InvalidLength(length)))
  base85_decode_groups_loop(bytes, bytes, alphabet, 0, [])
}

fn base85_decode_groups_loop(
  input: BitArray,
  rest: BitArray,
  alphabet: Alphabet,
  offset: Int,
  acc: List(BitArray),
) -> Result(BitArray, CodecError) {
  case rest {
    <<a, b, c, d, e, rest:bytes>> ->
      case base85_group_value([a, b, c, d, e], alphabet, 0, offset) {
        Ok(value) if value > base85_max_u32 -> Error(Overflow)
        Ok(value) ->
          base85_decode_groups_loop(input, rest, alphabet, offset + 5, [
            <<value:32>>,
            ..acc
          ])
        Error(bad) ->
          Error(alphabet_invalid_character(alphabet, input, bad, bad))
      }
    <<>> -> Ok(bit_array.concat(list.reverse(acc)))
    _ -> Error(alphabet_invalid_character(alphabet, input, offset, offset))
  }
}

// The value of a group of digits, or the offset of the first byte that is
// not a symbol.
fn base85_group_value(
  group: List(Int),
  alphabet: Alphabet,
  value: Int,
  offset: Int,
) -> Result(Int, Int) {
  case group {
    [] -> Ok(value)
    [byte, ..rest] ->
      case alphabet_lookup(alphabet, byte) {
        Value(digit) ->
          base85_group_value(rest, alphabet, value * 85 + digit, offset + 1)
        Ignored | Invalid -> Error(offset)
      }
  }
}

// Decode Ascii85 text. Space, tab, CR, LF and form feed are skipped and
// count as one position each (CR LF counts as one). A final group needs at
// least two characters. `position` is the position of the first byte of
// `input`, so errors can be reported against the caller's string.
fn base85_decode_ascii85(
  input: String,
  shortcuts: Shortcuts,
  position: Int,
  source: DecodeSource,
) -> Result(BitArray, CodecError) {
  let bytes = bit_array.from_string(input)
  base85_ascii85_loop(
    Reader(source:, alphabet: base85_ascii85_alphabet(), shortcuts:),
    bytes,
    0,
    position,
    [],
    [],
  )
}

type Reader {
  Reader(source: DecodeSource, alphabet: Alphabet, shortcuts: Shortcuts)
}

fn base85_ascii85_loop(
  reader: Reader,
  rest: BitArray,
  offset: Int,
  position: Int,
  group: List(Int),
  acc: List(BitArray),
) -> Result(BitArray, CodecError) {
  case rest, group {
    <<13, 10, rest:bytes>>, _ ->
      base85_ascii85_loop(reader, rest, offset + 2, position + 1, group, acc)
    <<byte, rest:bytes>>, _
      if byte == 32 || byte == 9 || byte == 10 || byte == 13 || byte == 12
    -> base85_ascii85_loop(reader, rest, offset + 1, position + 1, group, acc)
    <<"z":utf8, rest:bytes>>, [] if reader.shortcuts != NoShortcuts ->
      base85_ascii85_loop(reader, rest, offset + 1, position + 1, [], [
        <<0:32>>,
        ..acc
      ])
    <<"y":utf8, rest:bytes>>, [] if reader.shortcuts == ZeroAndSpaceShortcuts ->
      base85_ascii85_loop(reader, rest, offset + 1, position + 1, [], [
        <<0x20202020:32>>,
        ..acc
      ])
    <<byte, rest:bytes>>, _ ->
      case alphabet_lookup(reader.alphabet, byte) {
        Value(digit) ->
          case base85_push_digit([digit, ..group], acc) {
            Ok(#(group, acc)) ->
              base85_ascii85_loop(
                reader,
                rest,
                offset + 1,
                position + 1,
                group,
                acc,
              )
            Error(error) -> Error(error)
          }
        Ignored | Invalid ->
          Error(source_invalid_character(reader.source, offset))
      }
    _, [] -> Ok(bit_array.concat(list.reverse(acc)))
    _, [_] -> Error(InvalidLength(position))
    _, _ ->
      case base85_finish_group(group) {
        Ok(chunk) -> Ok(bit_array.concat(list.reverse([chunk, ..acc])))
        Error(error) -> Error(error)
      }
  }
}

// Add a digit to the current group, flushing the group once it has five.
fn base85_push_digit(
  group: List(Int),
  acc: List(BitArray),
) -> Result(#(List(Int), List(BitArray)), CodecError) {
  case list.length(group) {
    5 ->
      result.map(base85_finish_group(group), fn(chunk) { #([], [chunk, ..acc]) })
    _ -> Ok(#(group, acc))
  }
}

// Turn a group of 2 to 5 digits (most recent first) into bytes. A short
// group is padded with `u` (84) and yields one byte fewer than its digits.
fn base85_finish_group(group: List(Int)) -> Result(BitArray, CodecError) {
  let count = list.length(group)
  let digits = list.append(list.reverse(group), list.repeat(84, 5 - count))
  let value = list.fold(digits, 0, fn(value, digit) { value * 85 + digit })
  use <- bool.guard(when: value > base85_max_u32, return: Error(Overflow))
  bit_array.slice(<<value:32>>, 0, count - 1)
  |> result.replace_error(InvalidLength(count))
}

// Limbs of the output side of an encode are `radix^digits_per_limb`,
// kept below 2^36 so that `limb * 65_536 + carry` stays below 2^53.
const bignum_limb_ceiling = 68_719_476_736

// Decoded bytes are gathered in limbs of two bytes.
const bignum_byte_limb = 65_536

// Encode `data` as a number written in `alphabet`.
fn bignum_encode(data: BitArray, alphabet: Alphabet) -> String {
  let radix = alphabet_size(alphabet)
  let #(zeros, rest) = bignum_split_leading_zero_bytes(data, 0)
  let #(digits_per_limb, limb_base) = bignum_limb_shape(radix, 1, radix)
  let limbs = bignum_bytes_to_limbs(rest, limb_base, [])
  let digits = bignum_limbs_to_digits(limbs, radix, digits_per_limb, [])
  let zero = alphabet_symbol(alphabet, 0)
  list.append(
    list.repeat(zero, zeros),
    list.map(digits, alphabet_symbol(alphabet, _)),
  )
  |> alphabet_to_string
}

// Decode a number written in `alphabet` back to bytes.
fn bignum_decode(
  input: String,
  alphabet: Alphabet,
) -> Result(BitArray, CodecError) {
  let bytes = bit_array.from_string(input)
  case bignum_read_digits(bytes, bytes, alphabet, 0, 0, []) {
    Error(error) -> Error(error)
    Ok(digits) -> {
      let radix = alphabet_size(alphabet)
      let #(zeros, rest) = bignum_split_leading_zero_digits(digits, 0)
      let #(digits_per_limb, _) = bignum_limb_shape(radix, 1, radix)
      let limbs = bignum_digits_to_limbs(rest, radix, digits_per_limb, [])
      Ok(
        bit_array.concat([
          bignum_zero_bytes(zeros),
          bignum_limbs_to_bytes(limbs, []),
        ]),
      )
    }
  }
}

// The remainder of `data`, read as a big-endian number, divided by
// `divisor`.
fn bignum_remainder(data: BitArray, divisor: Int) -> Int {
  bignum_remainder_loop(data, divisor, 0)
}

fn bignum_remainder_loop(data: BitArray, divisor: Int, acc: Int) -> Int {
  case data {
    <<byte, rest:bytes>> ->
      bignum_remainder_loop(rest, divisor, { acc * 256 + byte } % divisor)
    _ -> acc
  }
}

// The largest `digits` with `radix^digits` below `limb_ceiling`, and that
// power.
fn bignum_limb_shape(radix: Int, digits: Int, power: Int) -> #(Int, Int) {
  use <- bool.guard(when: power * radix >= bignum_limb_ceiling, return: #(
    digits,
    power,
  ))
  bignum_limb_shape(radix, digits + 1, power * radix)
}

fn bignum_split_leading_zero_bytes(
  data: BitArray,
  count: Int,
) -> #(Int, BitArray) {
  case data {
    <<0, rest:bytes>> -> bignum_split_leading_zero_bytes(rest, count + 1)
    _ -> #(count, data)
  }
}

fn bignum_split_leading_zero_digits(
  digits: List(Int),
  count: Int,
) -> #(Int, List(Int)) {
  case digits {
    [0, ..rest] -> bignum_split_leading_zero_digits(rest, count + 1)
    _ -> #(count, digits)
  }
}

// Read the input bytes into digit values, most significant first.
fn bignum_read_digits(
  input: BitArray,
  rest: BitArray,
  alphabet: Alphabet,
  offset: Int,
  position: Int,
  acc: List(Int),
) -> Result(List(Int), CodecError) {
  case rest {
    <<byte, rest:bytes>> ->
      case alphabet_lookup(alphabet, byte) {
        Value(value) ->
          bignum_read_digits(input, rest, alphabet, offset + 1, position + 1, [
            value,
            ..acc
          ])
        Ignored ->
          bignum_read_digits(input, rest, alphabet, offset + 1, position, acc)
        Invalid ->
          Error(alphabet_invalid_character(alphabet, input, offset, position))
      }
    _ -> Ok(list.reverse(acc))
  }
}

// Fold big-endian bytes, two at a time, into limbs of `limb_base`.
fn bignum_bytes_to_limbs(
  data: BitArray,
  limb_base: Int,
  limbs: List(Int),
) -> List(Int) {
  case data {
    <<pair:16, rest:bytes>> ->
      bignum_bytes_to_limbs(
        rest,
        limb_base,
        bignum_multiply_add(limbs, bignum_byte_limb, pair, limb_base, []),
      )
    <<byte>> -> bignum_multiply_add(limbs, 256, byte, limb_base, [])
    _ -> limbs
  }
}

// Fold digits, `digits_per_limb` at a time, into limbs of two bytes.
fn bignum_digits_to_limbs(
  digits: List(Int),
  radix: Int,
  digits_per_limb: Int,
  limbs: List(Int),
) -> List(Int) {
  case digits {
    [] -> limbs
    _ -> {
      // Splitting the batch keeps the remaining list outside the numeric fold.
      // OTP 29 mis-infers its element range when both are returned by one loop.
      let #(batch, rest) = list.split(digits, digits_per_limb)
      let #(value, factor) =
        list.fold(batch, #(0, 1), fn(acc, digit) {
          #(acc.0 * radix + digit, acc.1 * radix)
        })
      bignum_digits_to_limbs(
        rest,
        radix,
        digits_per_limb,
        bignum_multiply_add(limbs, factor, value, bignum_byte_limb, []),
      )
    }
  }
}

// `limbs * factor + carry`, with limbs least significant first. The
// result is least significant first too.
fn bignum_multiply_add(
  limbs: List(Int),
  factor: Int,
  carry: Int,
  base: Int,
  acc: List(Int),
) -> List(Int) {
  case limbs {
    [limb, ..rest] -> {
      let value = limb * factor + carry
      bignum_multiply_add(rest, factor, value / base, base, [
        value % base,
        ..acc
      ])
    }
    [] -> list.reverse(bignum_push_carry(carry, base, acc))
  }
}

fn bignum_push_carry(carry: Int, base: Int, acc: List(Int)) -> List(Int) {
  case carry {
    0 -> acc
    _ -> bignum_push_carry(carry / base, base, [carry % base, ..acc])
  }
}

// Write limbs (least significant first) as digits, most significant
// first, without leading zero digits.
fn bignum_limbs_to_digits(
  limbs: List(Int),
  radix: Int,
  digits_per_limb: Int,
  acc: List(Int),
) -> List(Int) {
  case limbs {
    [] -> acc
    [top] -> bignum_limb_digits(top, radix, -1, acc)
    [limb, ..rest] ->
      bignum_limbs_to_digits(
        rest,
        radix,
        digits_per_limb,
        bignum_limb_digits(limb, radix, digits_per_limb, acc),
      )
  }
}

// Digits of one limb, most significant first. A negative `count` writes
// as many digits as the value needs.
fn bignum_limb_digits(
  limb: Int,
  radix: Int,
  count: Int,
  acc: List(Int),
) -> List(Int) {
  case count, limb {
    0, _ -> acc
    _, 0 if count < 0 -> acc
    _, _ ->
      bignum_limb_digits(limb / radix, radix, count - 1, [limb % radix, ..acc])
  }
}

// Write two-byte limbs (least significant first) as big-endian bytes
// without a leading zero byte.
fn bignum_limbs_to_bytes(limbs: List(Int), acc: List(BitArray)) -> BitArray {
  case limbs {
    [] -> bit_array.concat(acc)
    [top] if top < 256 -> bit_array.concat([<<top>>, ..acc])
    [limb, ..rest] -> bignum_limbs_to_bytes(rest, [<<limb:16>>, ..acc])
  }
}

fn bignum_zero_bytes(count: Int) -> BitArray {
  bit_array.concat(list.repeat(<<0>>, count))
}

const bitgroup_pad = 61

// Whether encoded output is padded with "=".
type Padding {
  Unpadded
  /// Pad with "=" to a multiple of this many characters.
  PaddedTo(block: Int)
}

// Encode `data` `bits` at a time. A final partial group is filled with
// zero bits. `data` must be a whole number of bytes.
fn bitgroup_encode(
  data: BitArray,
  bits: Int,
  alphabet: Alphabet,
  padding: Padding,
) -> String {
  let #(symbols, count) =
    bitgroup_encode_loop(data, bits, alphabet, 0, 0, [], 0)
  let padding_length = case padding {
    Unpadded -> 0
    PaddedTo(block) -> { block - count % block } % block
  }
  list.repeat(bitgroup_pad, padding_length)
  |> list.append(symbols)
  |> list.reverse
  |> alphabet_to_string
}

fn bitgroup_encode_loop(
  data: BitArray,
  bits: Int,
  alphabet: Alphabet,
  buffer: Int,
  buffered: Int,
  acc: List(Int),
  count: Int,
) -> #(List(Int), Int) {
  case buffered >= bits, data {
    True, _ -> {
      let shift = buffered - bits
      let value = int.bitwise_shift_right(buffer, shift)
      let rest = buffer - int.bitwise_shift_left(value, shift)
      bitgroup_encode_loop(
        data,
        bits,
        alphabet,
        rest,
        shift,
        [alphabet_symbol(alphabet, value), ..acc],
        count + 1,
      )
    }
    False, <<byte, data:bytes>> ->
      bitgroup_encode_loop(
        data,
        bits,
        alphabet,
        buffer * 256 + byte,
        buffered + 8,
        acc,
        count,
      )
    False, _ ->
      case buffered {
        0 -> #(acc, count)
        _ -> {
          let value = int.bitwise_shift_left(buffer, bits - buffered)
          #([alphabet_symbol(alphabet, value), ..acc], count + 1)
        }
      }
  }
}

// Decode input with no padding. Characters are checked first; then the
// bits left over after the last whole byte must be fewer than `bits`, or
// the result is `InvalidLength(character count)`. Leftover bits are
// dropped.
fn bitgroup_decode_unpadded(
  input: String,
  bits: Int,
  alphabet: Alphabet,
) -> Result(BitArray, CodecError) {
  let bytes = bit_array.from_string(input)
  use length <- bitgroup_check_characters(bytes, alphabet, -1)
  use <- bool.guard(
    when: length * bits % 8 >= bits,
    return: Error(InvalidLength(length)),
  )
  Ok(bitgroup_unpack(bytes, bits, alphabet))
}

// Decode input whose length must hold whole bytes exactly. The length is
// checked before the characters, and counts characters (graphemes).
fn bitgroup_decode_exact(
  input: String,
  bits: Int,
  alphabet: Alphabet,
) -> Result(BitArray, CodecError) {
  let bytes = bit_array.from_string(input)
  case bitgroup_first_invalid(bytes, alphabet, -1, 0) {
    Ok(length) ->
      case length * bits % 8 {
        0 -> Ok(bitgroup_unpack(bytes, bits, alphabet))
        _ -> Error(InvalidLength(length))
      }
    Error(offset) -> {
      let length = string.length(input)
      case length * bits % 8 {
        0 -> Error(alphabet_invalid_character(alphabet, bytes, offset, offset))
        _ -> Error(InvalidLength(length))
      }
    }
  }
}

// Decode RFC 4648 Base32 with optional "=" padding. Characters (and "=")
// are checked first, then the padding, then the length.
fn bitgroup_decode_base32_padded(
  input: String,
  alphabet: Alphabet,
) -> Result(BitArray, CodecError) {
  let bytes = bit_array.from_string(input)
  use length <- bitgroup_check_characters(bytes, alphabet, bitgroup_pad)
  let data_length = bitgroup_first_pad(bytes, 0)
  let has_padding = data_length < length
  use <- bool.guard(
    when: has_padding && length % 8 != 0,
    return: Error(InvalidLength(length)),
  )
  use <- bitgroup_only_padding_after(bytes, data_length)
  use <- bool.guard(
    when: has_padding && data_length == 0,
    return: Error(InvalidLength(length)),
  )
  use <- bool.guard(
    when: data_length * 5 % 8 >= 5,
    return: Error(InvalidLength(length)),
  )
  Ok(bitgroup_unpack(bitgroup_take(bytes, data_length), 5, alphabet))
}

// Decode RFC 4648 Base64 with mandatory "=" padding. Characters (and "=")
// are checked first, then the length, then each group of four.
fn bitgroup_decode_base64_padded(
  input: String,
  alphabet: Alphabet,
) -> Result(BitArray, CodecError) {
  let bytes = bit_array.from_string(input)
  use length <- bitgroup_check_characters(bytes, alphabet, bitgroup_pad)
  use <- bool.guard(when: length % 4 != 0, return: Error(InvalidLength(length)))
  case bitgroup_base64_data_length(bytes, length, 0) {
    Ok(data_length) ->
      Ok(bitgroup_unpack(bitgroup_take(bytes, data_length), 6, alphabet))
    Error(error) -> Error(error)
  }
}

// Where "=" may appear in padded Base64: as the last one or two characters
// of the final group. Returns the number of data characters.
fn bitgroup_base64_data_length(
  bytes: BitArray,
  length: Int,
  position: Int,
) -> Result(Int, CodecError) {
  case bytes {
    <<a, b, c, d, rest:bytes>> -> {
      let last = bit_array.byte_size(rest) == 0
      case
        c == bitgroup_pad && d == bitgroup_pad,
        d == bitgroup_pad,
        bitgroup_no_pad_in([a, b, c, d], position)
      {
        True, _, _ if !last -> Error(InvalidLength(length))
        _, True, _ if !last -> Error(InvalidLength(length))
        True, _, _ ->
          bitgroup_no_pad_in([a, b], position) |> result.replace(position + 2)
        _, True, _ ->
          bitgroup_no_pad_in([a, b, c], position)
          |> result.replace(position + 3)
        _, _, Error(error) -> Error(error)
        _, _, Ok(Nil) if last -> Ok(position + 4)
        _, _, Ok(Nil) -> bitgroup_base64_data_length(rest, length, position + 4)
      }
    }
    _ -> Ok(position)
  }
}

fn bitgroup_no_pad_in(
  group: List(Int),
  position: Int,
) -> Result(Nil, CodecError) {
  case group {
    [] -> Ok(Nil)
    [byte, ..] if byte == bitgroup_pad -> Error(InvalidCharacter("=", position))
    [_, ..rest] -> bitgroup_no_pad_in(rest, position + 1)
  }
}

// Check that every byte is a symbol (or `extra`), then continue with the
// character count. Only ASCII passes, so the count is also the byte count.
fn bitgroup_check_characters(
  bytes: BitArray,
  alphabet: Alphabet,
  extra: Int,
  next: fn(Int) -> Result(BitArray, CodecError),
) -> Result(BitArray, CodecError) {
  case bitgroup_first_invalid(bytes, alphabet, extra, 0) {
    Ok(length) -> next(length)
    Error(offset) ->
      Error(alphabet_invalid_character(alphabet, bytes, offset, offset))
  }
}

// The byte count if every byte is a symbol or `extra`, otherwise the
// offset of the first one that is not.
fn bitgroup_first_invalid(
  bytes: BitArray,
  alphabet: Alphabet,
  extra: Int,
  offset: Int,
) -> Result(Int, Int) {
  case bytes {
    <<byte, rest:bytes>> ->
      case byte == extra, alphabet_lookup(alphabet, byte) {
        True, _ | _, Value(_) ->
          bitgroup_first_invalid(rest, alphabet, extra, offset + 1)
        _, _ -> Error(offset)
      }
    _ -> Ok(offset)
  }
}

fn bitgroup_first_pad(bytes: BitArray, offset: Int) -> Int {
  case bytes {
    <<byte, _:bytes>> if byte == bitgroup_pad -> offset
    <<_, rest:bytes>> -> bitgroup_first_pad(rest, offset + 1)
    _ -> offset
  }
}

// Every byte from `from` on must be "="; a data character after padding
// is reported at the "=" just before it.
fn bitgroup_only_padding_after(
  bytes: BitArray,
  from: Int,
  next: fn() -> Result(BitArray, CodecError),
) -> Result(BitArray, CodecError) {
  case bit_array.slice(bytes, from, bit_array.byte_size(bytes) - from) {
    Ok(tail) ->
      case bitgroup_first_non_pad(tail, from) {
        Ok(Nil) -> next()
        Error(offset) -> Error(InvalidCharacter("=", offset - 1))
      }
    Error(Nil) -> next()
  }
}

fn bitgroup_first_non_pad(bytes: BitArray, offset: Int) -> Result(Nil, Int) {
  case bytes {
    <<byte, rest:bytes>> if byte == bitgroup_pad ->
      bitgroup_first_non_pad(rest, offset + 1)
    <<_, _:bytes>> -> Error(offset)
    _ -> Ok(Nil)
  }
}

fn bitgroup_take(bytes: BitArray, count: Int) -> BitArray {
  case bit_array.slice(bytes, 0, count) {
    Ok(head) -> head
    Error(Nil) -> bytes
  }
}

// Turn validated symbol bytes back into data bytes. Bits left over after
// the last whole byte are dropped.
fn bitgroup_unpack(bytes: BitArray, bits: Int, alphabet: Alphabet) -> BitArray {
  bitgroup_unpack_loop(bytes, bits, alphabet, 0, 0, [])
}

fn bitgroup_unpack_loop(
  bytes: BitArray,
  bits: Int,
  alphabet: Alphabet,
  buffer: Int,
  buffered: Int,
  acc: List(BitArray),
) -> BitArray {
  case buffered >= 8, bytes {
    True, _ -> {
      let shift = buffered - 8
      let byte = int.bitwise_shift_right(buffer, shift)
      let rest = buffer - int.bitwise_shift_left(byte, shift)
      bitgroup_unpack_loop(bytes, bits, alphabet, rest, shift, [<<byte>>, ..acc])
    }
    False, <<symbol, bytes:bytes>> -> {
      let value = case alphabet_lookup(alphabet, symbol) {
        Value(value) -> value
        // Callers validate the input first.
        Ignored | Invalid -> 0
      }
      bitgroup_unpack_loop(
        bytes,
        bits,
        alphabet,
        int.bitwise_shift_left(buffer, bits) + value,
        buffered + bits,
        acc,
      )
    }
    False, _ -> bit_array.concat(list.reverse(acc))
  }
}

// Encode a non-negative `Int` as a Base32 (RFC 4648) string.
// Returns `Error(NegativeValue(value))` for negative inputs; see
// the module note on "Negative inputs are rejected" for the
// rationale and the recommended boundary-check pattern.
fn intid_encode_int_base32_rfc4648(value: Int) -> Result(String, CodecError) {
  use bytes <- result.map(intid_int_to_bytes_be(value))
  base32_rfc4648_encode(bytes)
}

// Decode a Base32 (RFC 4648) string back to an `Int`.
fn intid_decode_int_base32_rfc4648(input: String) -> Result(Int, CodecError) {
  intid_decode_canonical(
    input,
    base32_rfc4648_decode,
    intid_encode_int_base32_rfc4648,
  )
}

// Encode a non-negative `Int` as a Crockford Base32 string.
// Returns `Error(NegativeValue(value))` for negative inputs; see
// the module note on "Negative inputs are rejected".
fn intid_encode_int_base32_crockford(value: Int) -> Result(String, CodecError) {
  use bytes <- result.map(intid_int_to_bytes_be(value))
  base32_crockford_encode(bytes)
}

// Decode a Crockford Base32 string back to an `Int`.
fn intid_decode_int_base32_crockford(input: String) -> Result(Int, CodecError) {
  intid_decode_canonical(
    input,
    base32_crockford_decode,
    intid_encode_int_base32_crockford,
  )
}

// Encode a non-negative `Int` as a Base10 (decimal) string.
// Returns `Error(NegativeValue(value))` for negative inputs; see
// the module note on "Negative inputs are rejected".
//
// Behaviour matches `int.to_string` for the typical case
// (positive integers) and the rest of the `intid` family for the
// switch-case bench harnesses described in #78. Routing through
// `base10.encode` keeps the contract uniform with the other
// `encode_int_*` functions: a non-negative `Int` in, a string
// in the alphabet out, no padding.
fn intid_encode_int_base10(value: Int) -> Result(String, CodecError) {
  use bytes <- result.map(intid_int_to_bytes_be(value))
  base10_encode(bytes)
}

// Decode a Base10 (decimal) string back to an `Int`.
fn intid_decode_int_base10(input: String) -> Result(Int, CodecError) {
  intid_decode_canonical(input, base10_decode, intid_encode_int_base10)
}

// Encode a non-negative `Int` as a Base16 (uppercase hexadecimal)
// string. Returns `Error(NegativeValue(value))` for negative
// inputs; see the module note on "Negative inputs are rejected".
//
// Routing through `base16.encode` keeps the contract uniform with
// the rest of the `encode_int_*` family. The output uses the
// canonical RFC 4648 §8 uppercase alphabet (`0-9 A-F`) — callers
// who need lowercase for interop with `sha256sum`-style tools can
// post-process with `string.lowercase`.
//
// ## Byte-aligned vs compact
//
// This function is **byte-aligned**: the output length is always an
// even number of hex characters because the encoding pads the
// integer's big-endian representation to a whole byte boundary
// (`encode_int_base16(1) == Ok("01")`,
// `encode_int_base16(2025) == Ok("07E9")`). This is the right
// shape for ID interop with byte-oriented systems (databases, HTTP
// headers, content-addressable storage). The other
// `encode_int_*` functions in this module are *compact* — they
// drop leading zero characters
// (`encode_int_base58(1) == Ok("2")`,
// `encode_int_base36(1) == Ok("1")`,
// `encode_int_base10(1) == Ok("1")`). Issue #99 surfaced the
// asymmetry; if you want the compact form for `base16`, use
// `encode_int_base16_compact/1` instead. `decode_int_base16/1`
// accepts either form (it does not require an even-length input).
fn intid_encode_int_base16(value: Int) -> Result(String, CodecError) {
  use bytes <- result.map(intid_int_to_bytes_be(value))
  base16_encode(bytes)
}

// Encode a non-negative `Int` as a Base16 (uppercase hexadecimal)
// string with leading zero characters stripped — the compact
// counterpart to `encode_int_base16/1`.
//
// ## Byte-aligned vs compact
//
// `encode_int_base16/1` is **byte-aligned** (always emits an even
// number of hex characters: `encode_int_base16(1) == Ok("01")`,
// `encode_int_base16(2025) == Ok("07E9")`). This function is
// **compact** — leading `"0"` characters are dropped so the
// output matches the shape of the rest of the `encode_int_*`
// family (`encode_int_base58(1) == Ok("2")`,
// `encode_int_base36(1) == Ok("1")`,
// `encode_int_base10(1) == Ok("1")`). Examples:
//
// ```gleam
// encode_int_base16_compact(0)      // Ok("0")
// encode_int_base16_compact(1)      // Ok("1")
// encode_int_base16_compact(255)    // Ok("FF")
// encode_int_base16_compact(2025)   // Ok("7E9")
// encode_int_base16_compact(0xdeadbeef) // Ok("DEADBEEF")
// ```
//
// Use this when you want column-aligned mixed-base output or
// round-trip-by-text comparisons across the `encode_int_*` family.
// Keep `encode_int_base16/1` for byte-oriented sinks where the
// even-length contract matters.
//
// `decode_int_base16/1` accepts the compact form unchanged
// (`decode_int_base16(encode_int_base16_compact(n) |> result.unwrap_or(""))`
// round-trips for every non-negative `Int`), because the
// integer decoder pads odd-length input to a byte boundary before
// calling `base16.decode`, whose input must have even length.
//
// Returns `Error(NegativeValue(value))` for negative inputs; see
// the module note on "Negative inputs are rejected".
//
// Added in #99.
fn intid_encode_int_base16_compact(value: Int) -> Result(String, CodecError) {
  use bytes <- result.map(intid_int_to_bytes_be(value))
  intid_drop_leading_zero_chars(base16_encode(bytes))
}

// Decode a canonical uppercase Base16 string back to an `Int`.
// Accepts the byte-aligned and compact encoder outputs; extra leading
// zeros and alternate letter case return `Error(NonCanonical)`.
//
// Odd-length inputs are accepted and internally zero-padded on the
// left to the next byte boundary before being passed to
// `base16.decode` (`"1"` is treated as `"01"`, `"7E9"` as
// `"07E9"`). This makes the function tolerant of either output
// shape from the `encode_int_base16*` family —
// `decode_int_base16(encode_int_base16(n)) == Ok(n)` *and*
// `decode_int_base16(encode_int_base16_compact(n)) == Ok(n)` both
// hold for every non-negative `Int`. The byte-oriented
// `base16.decode/1` keeps its strict even-length contract for
// callers reaching for the low-level codec directly. (#99)
fn intid_decode_int_base16(input: String) -> Result(Int, CodecError) {
  use input <- result.try(intid_reject_empty(input))
  let bytes = bit_array.from_string(input)
  let table = alphabet_new(base16_upper_symbols, FoldToLower)
  use _ <- result.try(
    bitgroup_first_invalid(bytes, table, -1, 0)
    |> result.map_error(fn(offset) {
      source_invalid_character(DecodeSource(input, 0), offset)
    }),
  )
  let padded = case int.is_odd(string.length(input)) {
    True -> "0" <> input
    False -> input
  }
  use bytes <- result.try(base16_decode(padded))
  use value <- result.try(intid_bytes_to_int(bytes))
  use aligned <- result.try(intid_encode_int_base16(value))
  use compact <- result.try(intid_encode_int_base16_compact(value))
  case input == aligned || input == compact {
    True -> Ok(value)
    False -> Error(NonCanonical)
  }
}

// Encode a non-negative `Int` as a Base36 string. Returns
// `Error(NegativeValue(value))` for negative inputs; see the
// module note on "Negative inputs are rejected".
fn intid_encode_int_base36(value: Int) -> Result(String, CodecError) {
  use bytes <- result.map(intid_int_to_bytes_be(value))
  base36_encode(bytes)
}

// Decode a Base36 string back to an `Int`.
fn intid_decode_int_base36(input: String) -> Result(Int, CodecError) {
  intid_decode_canonical(input, base36_decode, intid_encode_int_base36)
}

// Encode a non-negative `Int` as a Base58 (Bitcoin alphabet)
// string. Returns `Error(NegativeValue(value))` for negative
// inputs; see the module note on "Negative inputs are rejected".
fn intid_encode_int_base58(value: Int) -> Result(String, CodecError) {
  use bytes <- result.map(intid_int_to_bytes_be(value))
  base58_bitcoin_encode(bytes)
}

// Decode a Base58 (Bitcoin alphabet) string back to an `Int`,
// rejecting non-canonical wire forms with `Error(NonCanonical)`.
//
// The Bitcoin Base58 alphabet uses `"1"` as the zero character, so
// the byte-oriented `base58_bitcoin.decode` prepends one `0x00` byte
// for every leading `"1"` in the input. When that byte string is
// read back as a big-endian integer the leading zero bytes
// disappear, which means `"5Q"`, `"15Q"`, `"115Q"`, … all decode to
// the same `Int`. That collapses the bijection that ID callers
// (URL shorteners, idempotency keys, database lookups) rely on:
// two different wire strings can name the same row, breaking
// deduplication and cache invariants.
//
// The fix is to require the input to be byte-equal to the
// canonical encoding (`encode_int_base58(decoded) == input`). The
// only legal leading `"1"` is the single-character input `"1"`,
// which is the canonical encoding of `0`. Any other input that
// starts with `"1"` is `Error(NonCanonical)`. Closes #101.
fn intid_decode_int_base58(input: String) -> Result(Int, CodecError) {
  intid_decode_canonical(input, base58_bitcoin_decode, intid_encode_int_base58)
}

// Encode a non-negative `Int` as a Base58 (Flickr alphabet)
// string. Returns `Error(NegativeValue(value))` for negative
// inputs; see the module note on "Negative inputs are rejected".
fn intid_encode_int_base58_flickr(value: Int) -> Result(String, CodecError) {
  use bytes <- result.map(intid_int_to_bytes_be(value))
  base58_flickr_encode(bytes)
}

// Decode a Base58 (Flickr alphabet) string back to an `Int`.
fn intid_decode_int_base58_flickr(input: String) -> Result(Int, CodecError) {
  intid_decode_canonical(
    input,
    base58_flickr_decode,
    intid_encode_int_base58_flickr,
  )
}

// Encode a non-negative `Int` as a Crockford Base32 string with a
// trailing checksum symbol (Douglas Crockford's optional check
// character).
//
// Issue #73: same shape as `encode_int_base32_crockford` but with
// the typo-resistance guard the underlying codec already supports.
// Use the matching `decode_int_base32_crockford_check` to recover
// the integer; the decoder verifies the symbol and returns
// `Error(InvalidChecksum)` if the input was mistyped.
//
// Returns `Error(NegativeValue(value))` for negative inputs; see
// the module note on "Negative inputs are rejected".
fn intid_encode_int_base32_crockford_check(
  value: Int,
) -> Result(String, CodecError) {
  use bytes <- result.map(intid_int_to_bytes_be(value))
  base32_crockford_encode_check(bytes)
}

// Decode a checksummed Crockford Base32 string back to an `Int`,
// verifying the trailing check symbol.
fn intid_decode_int_base32_crockford_check(
  input: String,
) -> Result(Int, CodecError) {
  intid_decode_canonical(
    input,
    base32_crockford_decode_check,
    intid_encode_int_base32_crockford_check,
  )
}

// Decode a Base58Check string back to an `Int`, verifying the
// 4-byte SHA-256 checksum.
//
// Issue #73: returns the *payload* as an `Int`, ignoring the version
// byte (which `encode_int_base58check` always sets to `0`).
// Callers that need to inspect the version byte should reach for
// `yabase/base58check.decode/1` directly.
fn intid_decode_int_base58check(input: String) -> Result(Int, CodecError) {
  use input <- result.try(intid_reject_empty(input))
  use decoded <- result.try(base58check_decode(input))
  intid_canonical_payload(decoded.payload)
}

// Encode a non-negative `Int` as a Base62 string. Returns
// `Error(NegativeValue(value))` for negative inputs; see the
// module note on "Negative inputs are rejected".
fn intid_encode_int_base62(value: Int) -> Result(String, CodecError) {
  use bytes <- result.map(intid_int_to_bytes_be(value))
  base62_encode(bytes)
}

// Decode a Base62 string back to an `Int`.
fn intid_decode_int_base62(input: String) -> Result(Int, CodecError) {
  intid_decode_canonical(input, base62_decode, intid_encode_int_base62)
}

// ---------------------------------------------------------------------------
// Generic Encoding -> Int facade (#93)
//
// The per-base helpers above are the right tool when the codec is
// known at compile time. The facade is the right tool when the
// codec is picked at runtime (multibase auto-detection, user
// preference, config). The shape mirrors `yabase.encode` /
// `yabase.decode` so a call site that already uses the byte facade
// reads the integer-side call the same way.
// ---------------------------------------------------------------------------

// Encode an `Int` to a string using the supplied `Encoding`,
// dispatching to the matching `encode_int_*` helper. Negative
// inputs surface as `Error(NegativeValue(value))` exactly as the
// per-base helpers do; see the module note on "Negative inputs
// are rejected" for the rationale and the boundary-handling
// pattern.
//
// Returns `Error(UnsupportedForInt(name))` for encodings that have
// no integer codec wired up (every byte-only codec: `Base2`,
// `Base8`, `Base32(Hex|Clockwork|ZBase32)`, `Base45`, every
// `Base64` / `Base85` variant, `Base91`, `Bech32`). For
// `Base58Check`, the existing `encode_int_base58check/1` helper
// uses the fixed version byte `0x00`; reach for the generic
// facade with `encoding.base58_check(version)` to pin a different
// version.
fn intid_encode_int(
  encoding encoding: Encoding,
  value value: Int,
) -> Result(String, CodecError) {
  case encoding_int_codec(encoding) {
    IntBase10 -> intid_encode_int_base10(value)
    IntBase16 -> intid_encode_int_base16(value)
    IntBase32Rfc4648 -> intid_encode_int_base32_rfc4648(value)
    IntBase32Crockford -> intid_encode_int_base32_crockford(value)
    IntBase32CrockfordCheck -> intid_encode_int_base32_crockford_check(value)
    IntBase36 -> intid_encode_int_base36(value)
    IntBase58Bitcoin -> intid_encode_int_base58(value)
    IntBase58Flickr -> intid_encode_int_base58_flickr(value)
    IntBase58Check(version) -> {
      use bytes <- result.try(intid_int_to_bytes_be(value))
      base58check_encode(version, bytes)
    }
    IntBase62 -> intid_encode_int_base62(value)
    IntCodecUnsupported(name) -> Error(UnsupportedForInt(name))
  }
}

// Decode a string back to an `Int` using the supplied `Encoding`,
// dispatching to the matching `decode_int_*` helper.
//
// Empty input returns `Error(InvalidLength(0))` so callers can
// distinguish "no ID was supplied" from "the ID is zero" — the
// same contract as the per-base helpers.
//
// Returns `Error(UnsupportedForInt(name))` for encodings that have
// no integer codec wired up.
fn intid_decode_int(
  encoding encoding: Encoding,
  value value: String,
) -> Result(Int, CodecError) {
  case encoding_int_codec(encoding) {
    IntBase10 -> intid_decode_int_base10(value)
    IntBase16 -> intid_decode_int_base16(value)
    IntBase32Rfc4648 -> intid_decode_int_base32_rfc4648(value)
    IntBase32Crockford -> intid_decode_int_base32_crockford(value)
    IntBase32CrockfordCheck -> intid_decode_int_base32_crockford_check(value)
    IntBase36 -> intid_decode_int_base36(value)
    IntBase58Bitcoin -> intid_decode_int_base58(value)
    IntBase58Flickr -> intid_decode_int_base58_flickr(value)
    IntBase58Check(version) ->
      intid_decode_int_base58check_with_version(value, version)
    IntBase62 -> intid_decode_int_base62(value)
    IntCodecUnsupported(name) -> Error(UnsupportedForInt(name))
  }
}

fn intid_decode_int_base58check_with_version(
  input: String,
  version: Int,
) -> Result(Int, CodecError) {
  use input <- result.try(intid_reject_empty(input))
  use decoded <- result.try(base58check_decode(input))
  use _ <- result.try(check_version(version))
  use <- bool.guard(
    when: decoded.version != version,
    return: Error(UnexpectedVersion(version, decoded.version)),
  )
  intid_canonical_payload(decoded.payload)
}

// `decode_int_*` rejects the empty string so callers can distinguish
// "no input" from a zero-valued ID. The byte-oriented decoders keep
// their `Ok(<<>>)` semantics for round-tripping empty inputs.
fn intid_reject_empty(input: String) -> Result(String, CodecError) {
  use <- bool.guard(
    when: string.is_empty(input),
    return: Error(InvalidLength(0)),
  )
  Ok(input)
}

fn intid_bound_check(value: Int, max: Int) -> Result(Int, CodecError) {
  use <- bool.guard(when: value > max, return: Error(Overflow))
  Ok(value)
}

// Convert a non-negative `Int` into a canonical big-endian
// `BitArray` for the per-base encoders. Negative inputs are
// rejected with `Error(NegativeValue(_))` rather than silently
// absolutized — the historical `int.absolute_value` shortcut
// destroyed the sign and broke `decode(encode(n)) == n` for
// every `n < 0` (closed #84, regressed in #100). Zero is the
// only value that maps to a single zero byte; every other
// non-negative value is encoded with the minimum number of
// bytes required to represent its magnitude.
fn intid_int_to_bytes_be(value: Int) -> Result(BitArray, CodecError) {
  use <- bool.guard(when: value < 0, return: Error(NegativeValue(value)))
  use Nil <- result.try(intid_check_target_range(value))
  case value {
    0 -> Ok(<<0>>)
    _ -> Ok(intid_accumulate_bytes(value, []))
  }
}

fn intid_accumulate_bytes(num: Int, acc: List(BitArray)) -> BitArray {
  case num {
    0 -> bit_array.concat(acc)
    _ -> {
      let byte = num % 256
      intid_accumulate_bytes(num / 256, [<<byte>>, ..acc])
    }
  }
}

fn intid_bytes_to_int(data: BitArray) -> Result(Int, CodecError) {
  intid_bytes_to_int_loop(data, 0)
}

fn intid_bytes_to_int_loop(
  data: BitArray,
  acc: Int,
) -> Result(Int, CodecError) {
  case data {
    <<byte, rest:bytes>> -> {
      use Nil <- result.try(intid_check_target_range(acc * 256 + byte))
      intid_bytes_to_int_loop(rest, acc * 256 + byte)
    }
    _ -> Ok(acc)
  }
}

// Drop every leading `"0"` character from `s`. If the entire string
// is composed of `"0"` characters (the magnitude-zero case), preserve
// a single `"0"` so the compact form still has at least one digit —
// matching `encode_int_base10(0) == "0"`,
// `encode_int_base36(0) == "0"` etc. Used by
// `encode_int_base16_compact/1` to turn the byte-aligned output of
// `base16.encode` into the compact form expected by the rest of the
// `encode_int_*` family. (#99)
fn intid_drop_leading_zero_chars(s: String) -> String {
  use <- bool.guard(when: !string.starts_with(s, "0"), return: s)
  let rest = string.drop_start(s, 1)
  use <- bool.guard(when: string.is_empty(rest), return: "0")
  intid_drop_leading_zero_chars(rest)
}

@target(erlang)
fn intid_check_target_range(_value: Int) -> Result(Nil, CodecError) {
  Ok(Nil)
}

@target(javascript)
fn intid_check_target_range(value: Int) -> Result(Nil, CodecError) {
  use <- bool.guard(when: value > int53_max, return: Error(Overflow))
  Ok(Nil)
}

fn intid_decode_canonical(
  input: String,
  decode: fn(String) -> Result(BitArray, CodecError),
  encode: fn(Int) -> Result(String, CodecError),
) -> Result(Int, CodecError) {
  use input <- result.try(intid_reject_empty(input))
  use bytes <- result.try(decode(input))
  use value <- result.try(intid_bytes_to_int(bytes))
  use canonical <- result.try(encode(value))
  case input == canonical {
    True -> Ok(value)
    False -> Error(NonCanonical)
  }
}

fn intid_canonical_payload(bytes: BitArray) -> Result(Int, CodecError) {
  use value <- result.try(intid_bytes_to_int(bytes))
  use canonical <- result.try(intid_int_to_bytes_be(value))
  case bytes == canonical {
    True -> Ok(value)
    False -> Error(NonCanonical)
  }
}

const rfc1924_base85_symbols =
  "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz!#$%&()*+-;<=>?@^_`{|}~"

// Encode a BitArray to RFC 1924 Base85.
// Input length must be a multiple of 4 bytes; otherwise the result is
// Error(InvalidLength(byte length)). Whole-byte alignment was already checked.
fn rfc1924_base85_encode(data: BitArray) -> Result(String, CodecError) {
  use _ <- result.try(check_byte_alignment(data))
  let length = bit_array.byte_size(data)
  use <- bool.guard(when: length % 4 != 0, return: Error(InvalidLength(length)))
  Ok(base85_encode(
    data,
    alphabet_new(rfc1924_base85_symbols, CaseSensitive),
    NoShortcuts,
  ))
}

// Decode an RFC 1924 Base85 string to a BitArray.
// Input length must be a multiple of 5 characters.
fn rfc1924_base85_decode(input: String) -> Result(BitArray, CodecError) {
  base85_decode_groups(
    input,
    alphabet_new(rfc1924_base85_symbols, CaseSensitive),
  )
}

const z85_symbols =
  "0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ.-:+=^!/*?&<>()[]{}@%$#"

// Encode a BitArray to Z85.
// Returns Error(InvalidLength(byte length)) if the input length is not a
// multiple of 4. Whole-byte alignment was already checked.
fn z85_encode(data: BitArray) -> Result(String, CodecError) {
  use _ <- result.try(check_byte_alignment(data))
  let length = bit_array.byte_size(data)
  use <- bool.guard(when: length % 4 != 0, return: Error(InvalidLength(length)))
  Ok(base85_encode(data, alphabet_new(z85_symbols, CaseSensitive), NoShortcuts))
}

// Decode a Z85 string to a BitArray.
// Input length must be a multiple of 5.
fn z85_decode(input: String) -> Result(BitArray, CodecError) {
  base85_decode_groups(input, alphabet_new(z85_symbols, CaseSensitive))
}

fn check_version(version: Int) -> Result(Nil, CodecError) {
  use <- bool.guard(
    when: version < 0 || version > 255,
    return: Error(InvalidVersion(version)),
  )
  Ok(Nil)
}

// Transformed input retains its byte origin; only errors scan graphemes.
type DecodeSource {
  DecodeSource(original: String, byte_offset: Int)
}

fn source_invalid_character(source: DecodeSource, offset: Int) -> CodecError {
  let #(character, position) =
    source_character_at(
      string.to_graphemes(source.original),
      source.byte_offset + offset,
      0,
    )
  InvalidCharacter(character, position)
}

fn source_character_at(
  characters: List(String),
  offset: Int,
  position: Int,
) -> #(String, Int) {
  case characters {
    [] -> #("", position)
    [character, ..rest] -> {
      let bytes = bit_array.byte_size(bit_array.from_string(character))
      case offset < bytes {
        True -> #(character, position)
        False -> source_character_at(rest, offset - bytes, position + 1)
      }
    }
  }
}

fn source_position(original: String, byte_offset: Int) -> Int {
  source_character_at(string.to_graphemes(original), byte_offset, 0).1
}

// Unicode Pattern_White_Space, pinned rather than delegated to target trim.
fn adobe_trim_span(
  points: List(UtfCodepoint),
  offset: Int,
  first: Int,
  end: Int,
) -> #(Int, Int) {
  case points {
    [point, ..rest] -> {
      let code = string.utf_codepoint_to_int(point)
      let next = offset + bit_array.byte_size(<<point:utf8_codepoint>>)
      let whitespace =
        code >= 9
        && code <= 13
        || code == 32
        || code == 133
        || code == 8206
        || code == 8207
        || code == 8232
        || code == 8233
      let start = case first < 0 {
        True -> offset
        False -> first
      }
      case whitespace {
        True -> adobe_trim_span(rest, next, first, end)
        False -> adobe_trim_span(rest, next, start, next)
      }
    }
    _ ->
      case first < 0 {
        True -> #(offset, offset)
        False -> #(first, end)
      }
  }
}

type DqSymbol {
  DqDigit(Int)
  DqPad
}

fn base64_dq_parse(
  chars: List(String),
  position: Int,
  acc: List(DqSymbol),
) -> Result(List(DqSymbol), CodecError) {
  case chars {
    [] -> Ok(list.reverse(acc))
    [character, ..rest] if character == base64_dq_dq_pad ->
      base64_dq_parse(rest, position + 1, [DqPad, ..acc])
    [character, ..rest] ->
      case base64_dq_dq_value_of(character) {
        Ok(value) ->
          base64_dq_parse(rest, position + 1, [DqDigit(value), ..acc])
        Error(Nil) -> Error(InvalidCharacter(character, position))
      }
  }
}

fn base64_dq_decode_symbols(
  symbols: List(DqSymbol),
  acc: List(BitArray),
  position: Int,
  length: Int,
) -> Result(BitArray, CodecError) {
  case symbols {
    [] -> Ok(base64_dq_finish(acc))
    // The old layout check precedes misplaced padding in this group.
    [_, _, _, DqPad, _, ..] -> Error(InvalidLength(length))
    [DqDigit(a), DqDigit(b), DqPad, DqPad] ->
      Ok(base64_dq_finish([<<{ a * 4 + b / 16 }>>, ..acc]))
    [DqDigit(a), DqDigit(b), DqDigit(c), DqPad] ->
      Ok(
        base64_dq_finish([
          <<{ a * 4 + b / 16 }, { { b % 16 } * 16 + c / 4 }>>,
          ..acc
        ]),
      )
    [DqDigit(a), DqDigit(b), DqDigit(c), DqDigit(d), ..rest] ->
      base64_dq_decode_symbols(
        rest,
        [
          <<
            { a * 4 + b / 16 },
            { { b % 16 } * 16 + c / 4 },
            { { c % 4 } * 64 + d },
          >>,
          ..acc
        ],
        position + 4,
        length,
      )
    [DqPad, ..] -> Error(InvalidCharacter(base64_dq_dq_pad, position))
    [_, DqPad, ..] -> Error(InvalidCharacter(base64_dq_dq_pad, position + 1))
    [_, _, DqPad, ..] -> Error(InvalidCharacter(base64_dq_dq_pad, position + 2))
    _ -> Error(InvalidLength(length))
  }
}

// The callers supply codepoint boundaries from the original String scan or
// validated two-byte ASCII delimiters. These assertions protect private
// invariants, not caller validation; malformed codec input returns CodecError.
fn source_slice(bytes: BitArray, start: Int, length: Int) -> String {
  // nolint: assert_ok_pattern
  let assert Ok(slice) = bit_array.slice(bytes, start, length)
    as "source span must remain inside the original UTF-8 input"
  source_text(slice)
}

fn source_text(bytes: BitArray) -> String {
  // nolint: assert_ok_pattern
  let assert Ok(text) = bit_array.to_string(bytes)
    as "source bytes must be an original String span on UTF-8 boundaries"
  text
}

fn base91_take_value(queue: Int) -> #(Int, Int) {
  let low13 = int.bitwise_and(queue, 8191)
  case low13 > 88 {
    True -> #(low13, 13)
    False -> #(int.bitwise_and(queue, 16_383), 14)
  }
}

fn base91_finish_pending(
  pending: Int,
  queue: Int,
  queued: Int,
  acc: List(BitArray),
) -> List(BitArray) {
  use <- bool.guard(when: pending == -1, return: acc)
  let last = int.bitwise_or(queue, int.bitwise_shift_left(pending, queued))
  [<<{ int.bitwise_and(last, 255) }>>, ..acc]
}

fn bech32_check_hrp_character(
  character: String,
  position: Int,
) -> Result(Nil, CodecError) {
  case string.to_utf_codepoints(character) {
    [codepoint] -> {
      let code = string.utf_codepoint_to_int(codepoint)
      use <- bool.guard(
        when: code < 33 || code > 126,
        return: Error(InvalidHrp(
          "character out of range at " <> int.to_string(position),
        )),
      )
      Ok(Nil)
    }
    _ -> Error(InvalidHrp("invalid character"))
  }
}

// Only malformed, unaligned input takes this tail-recursive counting path.
fn count_input_bits(input: BitArray, count: Int) -> Int {
  case input {
    <<_:size(32_768), rest:bits>> -> count_input_bits(rest, count + 32_768)
    <<_:size(8), rest:bits>> -> count_input_bits(rest, count + 8)
    <<_:size(1), rest:bits>> -> count_input_bits(rest, count + 1)
    _ -> count
  }
}
