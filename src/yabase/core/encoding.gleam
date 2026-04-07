/// Core encoding types for yabase.
/// Variants for Base32 encoding.
pub type Base32Variant {
  /// RFC 4648 standard Base32
  RFC4648
  /// RFC 4648 Base32 with extended hex alphabet
  Hex
  /// Crockford's Base32
  Crockford
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

/// Represents a supported encoding scheme.
pub type Encoding {
  Base2
  Base16
  Base32(Base32Variant)
  Base36
  Base45
  Base58(Base58Variant)
  Base62
  Base64(Base64Variant)
  Base91
  Ascii85
  AdobeAscii85
  Rfc1924Base85
  Z85
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
