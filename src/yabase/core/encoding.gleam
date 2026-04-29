/// Core encoding types for yabase.
/// Variants for Base32 encoding.
pub type Base32Variant {
  /// RFC 4648 standard Base32
  RFC4648
  /// RFC 4648 Base32 with extended hex alphabet
  Hex
  /// Crockford's Base32
  Crockford
  /// Crockford's Base32 with mod-37 check symbol
  CrockfordCheck
  /// Clockwork Base32 (human-friendly, no padding)
  Clockwork
  /// z-base-32 (human-oriented, no padding)
  ZBase32
}

/// Variants for Base64 encoding.
pub type Base64Variant {
  /// RFC 4648 standard Base64 (with padding)
  Standard
  /// URL-safe Base64 with padding (RFC 4648 section 5)
  UrlSafe
  /// Standard Base64 without padding
  NoPadding
  /// URL-safe Base64 without padding
  UrlSafeNoPadding
  /// Dragon Quest revival password style Base64 (hiragana)
  DQ
}

/// Variants for Base58 encoding.
pub type Base58Variant {
  /// Bitcoin alphabet (uppercase before lowercase)
  Bitcoin
  /// Flickr alphabet (lowercase before uppercase)
  Flickr
}

/// Variants for Base85 encoding.
pub type Base85Variant {
  /// btoa-style Ascii85 (z for all-zero, y for all-space)
  Btoa
  /// Adobe Ascii85 with <~ ~> delimiters
  Adobe
  /// RFC 1924 alphabet (input must be 4-byte aligned)
  Rfc1924
  /// ZeroMQ Z85 (input must be 4-byte aligned)
  Z85
}

/// Represents a supported encoding scheme.
pub type Encoding {
  Base2
  Base8
  Base10
  Base16
  Base32(Base32Variant)
  Base36
  Base45
  Base58(Base58Variant)
  Base62
  Base64(Base64Variant)
  Base85(Base85Variant)
  Base91
}

/// A decoded value tagged with its detected encoding.
pub type Decoded {
  Decoded(encoding: Encoding, data: BitArray)
}

/// Bech32 encoding variant.
pub type Bech32Variant {
  /// BIP 173 original Bech32
  Bech32
  /// BIP 350 improved Bech32m
  Bech32m
}

/// Result of decoding a Bech32/Bech32m string.
pub type Bech32Decoded {
  Bech32Decoded(hrp: String, data: BitArray, variant: Bech32Variant)
}

/// Result of decoding a Base58Check string.
pub type Base58CheckDecoded {
  Base58CheckDecoded(version: Int, payload: BitArray)
}

/// Errors that can occur during encoding or decoding.
pub type CodecError {
  /// Input contains a character not in the encoding's alphabet.
  InvalidCharacter(character: String, position: Int)
  /// Input length is not valid for the encoding.
  InvalidLength(length: Int)
  /// Decoded value overflows the expected range.
  Overflow
  /// An unknown multibase prefix was encountered during decode.
  UnsupportedPrefix(prefix: String)
  /// An encoding has no assigned multibase prefix (e.g. Base64 DQ).
  UnsupportedMultibaseEncoding(encoding_name: String)
  /// Checksum verification failed (Base58Check, Bech32).
  InvalidChecksum
  /// Invalid human-readable part in Bech32/Bech32m.
  InvalidHrp(reason: String)
}

// ---------------------------------------------------------------------------
// Smart constructors.
//
// These are the recommended way to construct `Encoding` values. They
// mirror the existing variants — `base32_rfc4648/0` for
// `Base32(RFC4648)`, `base64_standard/0` for `Base64(Standard)`, etc. —
// and stay stable across releases even when the variant ADTs change
// shape. The constructor list is still public for now (so existing
// `Base32(RFC4648)` call sites keep working unchanged); promoting the
// types to `pub opaque type` for full constructor hiding is tracked
// as a separate larger refactor (see #32 follow-up notes).
// ---------------------------------------------------------------------------

/// Binary (base-2) encoding.
pub fn base2() -> Encoding {
  Base2
}

/// Octal (base-8) encoding.
pub fn base8() -> Encoding {
  Base8
}

/// Decimal (base-10) encoding.
pub fn base10() -> Encoding {
  Base10
}

/// Hexadecimal (base-16) encoding.
pub fn base16() -> Encoding {
  Base16
}

/// RFC 4648 standard Base32.
pub fn base32_rfc4648() -> Encoding {
  Base32(RFC4648)
}

/// RFC 4648 Base32 with extended hex alphabet.
pub fn base32_hex() -> Encoding {
  Base32(Hex)
}

/// Crockford's Base32.
pub fn base32_crockford() -> Encoding {
  Base32(Crockford)
}

/// Crockford's Base32 with mod-37 check symbol.
pub fn base32_crockford_check() -> Encoding {
  Base32(CrockfordCheck)
}

/// Clockwork Base32 (human-friendly, no padding).
pub fn base32_clockwork() -> Encoding {
  Base32(Clockwork)
}

/// z-base-32 (human-oriented, no padding).
pub fn base32_z_base32() -> Encoding {
  Base32(ZBase32)
}

/// Base36 encoding.
pub fn base36() -> Encoding {
  Base36
}

/// Base45 encoding (RFC 9285).
pub fn base45() -> Encoding {
  Base45
}

/// Base58 with the Bitcoin alphabet.
pub fn base58_bitcoin() -> Encoding {
  Base58(Bitcoin)
}

/// Base58 with the Flickr alphabet.
pub fn base58_flickr() -> Encoding {
  Base58(Flickr)
}

/// Base62 encoding.
pub fn base62() -> Encoding {
  Base62
}

/// RFC 4648 standard Base64 (with padding).
pub fn base64_standard() -> Encoding {
  Base64(Standard)
}

/// URL-safe Base64 with padding (RFC 4648 section 5).
pub fn base64_url_safe() -> Encoding {
  Base64(UrlSafe)
}

/// Standard Base64 without padding.
pub fn base64_no_padding() -> Encoding {
  Base64(NoPadding)
}

/// URL-safe Base64 without padding.
pub fn base64_url_safe_no_padding() -> Encoding {
  Base64(UrlSafeNoPadding)
}

/// Dragon Quest revival password style Base64 (hiragana).
pub fn base64_dq() -> Encoding {
  Base64(DQ)
}

/// btoa-style Ascii85.
pub fn base85_btoa() -> Encoding {
  Base85(Btoa)
}

/// Adobe Ascii85 with `<~` `~>` delimiters.
pub fn base85_adobe() -> Encoding {
  Base85(Adobe)
}

/// RFC 1924 Base85.
pub fn base85_rfc1924() -> Encoding {
  Base85(Rfc1924)
}

/// ZeroMQ Z85 Base85.
pub fn base85_z85() -> Encoding {
  Base85(Z85)
}

/// Base91 encoding.
pub fn base91() -> Encoding {
  Base91
}
