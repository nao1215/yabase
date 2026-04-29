/// Error and result types shared across yabase's per-base modules.
///
/// These types are split out of `core/encoding` so the per-base modules
/// (`yabase/base32/rfc4648`, `yabase/z85`, …) can depend on them
/// without forming an import cycle: `core/encoding` aggregates the
/// per-base modules to provide the `Encoding` dispatcher, so the
/// per-base modules cannot in turn import `core/encoding`.
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
  /// The decoded bytes are valid but the wire encoding is not the
  /// canonical form. Per RFC 4648 §3.5, the pad bits in base32 /
  /// base64 must be zero on the encoder side; decoders MAY reject
  /// non-canonical input. The strict-variant decoders surface this
  /// rejection so callers that need wire-form uniqueness (signature
  /// verification, content-addressable storage, audit comparisons)
  /// can opt into it.
  NonCanonical
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
