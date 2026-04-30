/// Core encoding type for yabase.
///
/// `Encoding` and the per-base variant ADTs (`Base32Variant`,
/// `Base58Variant`, `Base64Variant`, `Base85Variant`) are
/// `pub opaque type`. Package-external callers cannot construct them
/// directly or pattern-match on the constructor list. The supported
/// way to obtain an `Encoding` value is the smart constructors at the
/// bottom of this module (`base32_rfc4648/0`, `base64_standard/0`, …);
/// the supported way to use one is `encode/2` / `decode_as/2`, the
/// per-base helpers in `yabase/facade`, or the multibase helpers in
/// `yabase/core/multibase`. Hiding the constructors lets the variant
/// list grow on a non-breaking minor instead of forcing a SemVer-major
/// every time a new alphabet is added.
import gleam/string
import yabase/adobe_ascii85
import yabase/ascii85
import yabase/base10
import yabase/base16
import yabase/base2
import yabase/base32/clockwork
import yabase/base32/crockford
import yabase/base32/hex as base32_hex_module
import yabase/base32/rfc4648 as base32_rfc4648_module
import yabase/base32/zbase32
import yabase/base36 as base36_module
import yabase/base45 as base45_module
import yabase/base58/bitcoin as base58_bitcoin_module
import yabase/base58/flickr as base58_flickr_module
import yabase/base62 as base62_module
import yabase/base64/dq as base64_dq_module
import yabase/base64/nopadding as base64_nopadding_module
import yabase/base64/standard as base64_standard_module
import yabase/base64/urlsafe as base64_urlsafe_module
import yabase/base64/urlsafe_nopadding as base64_urlsafe_nopadding_module
import yabase/base8
import yabase/base91 as base91_module
import yabase/core/error.{type CodecError as CodecErrorAlias}
import yabase/rfc1924_base85
import yabase/z85 as z85_module

/// Re-export of `error.CodecError` so the historical
/// `import yabase/core/encoding.{type CodecError}` shape keeps working.
/// Other error types (`Bech32Variant`, `Bech32Decoded`,
/// `Base58CheckDecoded`) are no longer re-exported — import them
/// directly from `yabase/core/error`.
pub type CodecError =
  CodecErrorAlias

/// Variants for Base32 encoding.
pub opaque type Base32Variant {
  RFC4648
  Hex
  Crockford
  CrockfordCheck
  Clockwork
  ZBase32
}

/// Variants for Base64 encoding.
pub opaque type Base64Variant {
  Standard
  UrlSafe
  NoPadding
  UrlSafeNoPadding
  DQ
}

/// Variants for Base58 encoding.
pub opaque type Base58Variant {
  Bitcoin
  Flickr
}

/// Variants for Base85 encoding.
pub opaque type Base85Variant {
  Btoa
  Adobe
  Rfc1924
  Z85
}

/// Represents a supported encoding scheme.
pub opaque type Encoding {
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

// ---------------------------------------------------------------------------
// Smart constructors. The only supported way to build an `Encoding`.
// ---------------------------------------------------------------------------

pub fn base2() -> Encoding {
  Base2
}

pub fn base8() -> Encoding {
  Base8
}

pub fn base10() -> Encoding {
  Base10
}

pub fn base16() -> Encoding {
  Base16
}

pub fn base32_rfc4648() -> Encoding {
  Base32(RFC4648)
}

pub fn base32_hex() -> Encoding {
  Base32(Hex)
}

pub fn base32_crockford() -> Encoding {
  Base32(Crockford)
}

pub fn base32_crockford_check() -> Encoding {
  Base32(CrockfordCheck)
}

pub fn base32_clockwork() -> Encoding {
  Base32(Clockwork)
}

pub fn base32_z_base32() -> Encoding {
  Base32(ZBase32)
}

pub fn base36() -> Encoding {
  Base36
}

pub fn base45() -> Encoding {
  Base45
}

pub fn base58_bitcoin() -> Encoding {
  Base58(Bitcoin)
}

pub fn base58_flickr() -> Encoding {
  Base58(Flickr)
}

pub fn base62() -> Encoding {
  Base62
}

pub fn base64_standard() -> Encoding {
  Base64(Standard)
}

pub fn base64_url_safe() -> Encoding {
  Base64(UrlSafe)
}

pub fn base64_no_padding() -> Encoding {
  Base64(NoPadding)
}

pub fn base64_url_safe_no_padding() -> Encoding {
  Base64(UrlSafeNoPadding)
}

pub fn base64_dq() -> Encoding {
  Base64(DQ)
}

pub fn base85_btoa() -> Encoding {
  Base85(Btoa)
}

pub fn base85_adobe() -> Encoding {
  Base85(Adobe)
}

pub fn base85_rfc1924() -> Encoding {
  Base85(Rfc1924)
}

pub fn base85_z85() -> Encoding {
  Base85(Z85)
}

pub fn base91() -> Encoding {
  Base91
}

// ---------------------------------------------------------------------------
// Target capabilities.
//
// Some encodings produce correct results regardless of compilation
// target; others rely on arbitrary-precision integer arithmetic and
// cannot represent inputs larger than `Number.MAX_SAFE_INTEGER` on
// JavaScript. The README explains the underlying constraint, but
// callers that need to *select* an encoding at runtime (multibase
// auto-detection, user-configurable codec choice) must be able to
// branch on this property programmatically.
// ---------------------------------------------------------------------------

/// A Gleam compilation target. Construct with `target_erlang/0` or
/// `target_javascript/0` and pass to `supports_target/2`.
pub opaque type Target {
  Erlang
  JavaScript
}

/// The Erlang/BEAM target.
pub fn target_erlang() -> Target {
  Erlang
}

/// The JavaScript target (Node.js or browser).
pub fn target_javascript() -> Target {
  JavaScript
}

/// True if the encoding produces correct results on the JavaScript
/// target for inputs of any size.
///
/// Encodings whose internals rely on arbitrary-precision integer
/// arithmetic (`base8`, `base10`, `base32` Crockford / CrockfordCheck,
/// `base36`, `base58` Bitcoin / Flickr, `base62`) inherit JavaScript's
/// `Number.MAX_SAFE_INTEGER` (2^53 - 1) ceiling and may produce
/// incorrect output for inputs that represent integers above that
/// bound — this returns `False` for them.
///
/// Byte-oriented encodings (`base2`, `base16`, `base32` RFC4648 /
/// Hex / Clockwork / ZBase32, `base45`, `base64` *, `base85` *,
/// `base91`) are correct on both targets — this returns `True` for
/// them.
pub fn is_javascript_safe(enc: Encoding) -> Bool {
  case enc {
    Base2 | Base16 | Base45 | Base91 -> True
    Base8 | Base10 | Base36 | Base62 -> False
    Base32(variant) ->
      case variant {
        RFC4648 | Hex | Clockwork | ZBase32 -> True
        Crockford | CrockfordCheck -> False
      }
    Base58(_) -> False
    Base64(_) -> True
    Base85(_) -> True
  }
}

/// True if the encoding works correctly on the given target.
///
/// All encodings work on the Erlang target (BEAM has bignum
/// integers). On JavaScript, this delegates to `is_javascript_safe/1`.
///
/// Useful for filtering an `Encoding` value picked at runtime — for
/// example, after `multibase.decode` auto-detects the encoding from
/// a prefix supplied by an untrusted source — before running the
/// decoded payload through downstream logic.
pub fn supports_target(enc: Encoding, target: Target) -> Bool {
  case target {
    Erlang -> True
    JavaScript -> is_javascript_safe(enc)
  }
}

// ---------------------------------------------------------------------------
// Dispatch.
// ---------------------------------------------------------------------------

/// Encode data using the specified encoding.
pub fn encode(enc: Encoding, data: BitArray) -> Result(String, CodecError) {
  case enc {
    Base2 -> Ok(base2.encode(data))
    Base8 -> Ok(base8.encode(data))
    Base10 -> Ok(base10.encode(data))
    Base16 -> Ok(base16.encode(data))
    Base32(RFC4648) -> Ok(base32_rfc4648_module.encode(data))
    Base32(Hex) -> Ok(base32_hex_module.encode(data))
    Base32(Crockford) -> Ok(crockford.encode(data))
    Base32(CrockfordCheck) -> Ok(crockford.encode_check(data))
    Base32(Clockwork) -> Ok(clockwork.encode(data))
    Base32(ZBase32) -> Ok(zbase32.encode(data))
    Base36 -> Ok(base36_module.encode(data))
    Base45 -> Ok(base45_module.encode(data))
    Base58(Bitcoin) -> Ok(base58_bitcoin_module.encode(data))
    Base58(Flickr) -> Ok(base58_flickr_module.encode(data))
    Base62 -> Ok(base62_module.encode(data))
    Base64(Standard) -> Ok(base64_standard_module.encode(data))
    Base64(UrlSafe) -> Ok(base64_urlsafe_module.encode(data))
    Base64(NoPadding) -> Ok(base64_nopadding_module.encode(data))
    Base64(UrlSafeNoPadding) -> Ok(base64_urlsafe_nopadding_module.encode(data))
    Base64(DQ) -> Ok(base64_dq_module.encode(data))
    Base85(Btoa) -> Ok(ascii85.encode(data))
    Base85(Adobe) -> Ok(adobe_ascii85.encode(data))
    Base85(Rfc1924) -> rfc1924_base85.encode(data)
    Base85(Z85) -> z85_module.encode(data)
    Base91 -> Ok(base91_module.encode(data))
  }
}

/// Decode a string using the specified encoding.
pub fn decode_as(enc: Encoding, value: String) -> Result(BitArray, CodecError) {
  case enc {
    Base2 -> base2.decode(value)
    Base8 -> base8.decode(value)
    Base10 -> base10.decode(value)
    Base16 -> base16.decode(value)
    Base32(RFC4648) -> base32_rfc4648_module.decode(value)
    Base32(Hex) -> base32_hex_module.decode(value)
    Base32(Crockford) -> crockford.decode(value)
    Base32(CrockfordCheck) -> crockford.decode_check(value)
    Base32(Clockwork) -> clockwork.decode(value)
    Base32(ZBase32) -> zbase32.decode(value)
    Base36 -> base36_module.decode(value)
    Base45 -> base45_module.decode(value)
    Base58(Bitcoin) -> base58_bitcoin_module.decode(value)
    Base58(Flickr) -> base58_flickr_module.decode(value)
    Base62 -> base62_module.decode(value)
    Base64(Standard) -> base64_standard_module.decode(value)
    Base64(UrlSafe) -> base64_urlsafe_module.decode(value)
    Base64(NoPadding) -> base64_nopadding_module.decode(value)
    Base64(UrlSafeNoPadding) -> base64_urlsafe_nopadding_module.decode(value)
    Base64(DQ) -> base64_dq_module.decode(value)
    Base85(Btoa) -> ascii85.decode(value)
    Base85(Adobe) -> adobe_ascii85.decode(value)
    Base85(Rfc1924) -> rfc1924_base85.decode(value)
    Base85(Z85) -> z85_module.decode(value)
    Base91 -> base91_module.decode(value)
  }
}

// ---------------------------------------------------------------------------
// Multibase metadata.
// ---------------------------------------------------------------------------

/// Map an `Encoding` to its official multibase prefix character.
pub fn multibase_prefix(enc: Encoding) -> Result(String, Nil) {
  case enc {
    Base2 -> Ok("0")
    Base8 -> Ok("7")
    Base10 -> Ok("9")
    Base16 -> Ok("f")
    Base32(RFC4648) -> Ok("c")
    Base32(Hex) -> Ok("t")
    Base32(Crockford) -> Error(Nil)
    Base32(CrockfordCheck) -> Error(Nil)
    Base32(Clockwork) -> Error(Nil)
    Base32(ZBase32) -> Ok("h")
    Base36 -> Ok("k")
    Base45 -> Ok("R")
    Base58(Bitcoin) -> Ok("z")
    Base58(Flickr) -> Ok("Z")
    Base62 -> Error(Nil)
    Base64(Standard) -> Ok("M")
    Base64(UrlSafe) -> Ok("U")
    Base64(NoPadding) -> Ok("m")
    Base64(UrlSafeNoPadding) -> Ok("u")
    Base64(DQ) -> Error(Nil)
    Base85(Btoa) -> Error(Nil)
    Base85(Adobe) -> Error(Nil)
    Base85(Rfc1924) -> Error(Nil)
    Base85(Z85) -> Error(Nil)
    Base91 -> Error(Nil)
  }
}

/// Map a multibase prefix character to its `Encoding`.
pub fn from_multibase_prefix(prefix: String) -> Result(Encoding, Nil) {
  case prefix {
    "0" -> Ok(Base2)
    "7" -> Ok(Base8)
    "9" -> Ok(Base10)
    "f" | "F" -> Ok(Base16)
    "c" | "C" -> Ok(Base32(RFC4648))
    "b" | "B" -> Ok(Base32(RFC4648))
    "t" | "T" -> Ok(Base32(Hex))
    "v" | "V" -> Ok(Base32(Hex))
    "k" | "K" -> Ok(Base36)
    "R" -> Ok(Base45)
    "z" -> Ok(Base58(Bitcoin))
    "Z" -> Ok(Base58(Flickr))
    "h" -> Ok(Base32(ZBase32))
    "M" -> Ok(Base64(Standard))
    "m" -> Ok(Base64(NoPadding))
    "U" -> Ok(Base64(UrlSafe))
    "u" -> Ok(Base64(UrlSafeNoPadding))
    _ -> Error(Nil)
  }
}

/// Human-readable name for an `Encoding`.
pub fn multibase_name(enc: Encoding) -> String {
  case enc {
    Base2 -> "base2"
    Base8 -> "base8"
    Base10 -> "base10"
    Base16 -> "base16"
    Base32(RFC4648) -> "base32pad"
    Base32(Hex) -> "base32hexpad"
    Base32(Crockford) -> "base32crockford"
    Base32(CrockfordCheck) -> "base32crockford-check"
    Base32(Clockwork) -> "base32clockwork"
    Base32(ZBase32) -> "base32z"
    Base36 -> "base36"
    Base45 -> "base45"
    Base58(Bitcoin) -> "base58btc"
    Base58(Flickr) -> "base58flickr"
    Base62 -> "base62"
    Base64(Standard) -> "base64pad"
    Base64(UrlSafe) -> "base64urlpad"
    Base64(NoPadding) -> "base64"
    Base64(UrlSafeNoPadding) -> "base64url"
    Base64(DQ) -> "base64dq"
    Base85(Btoa) -> "ascii85"
    Base85(Adobe) -> "adobe-ascii85"
    Base85(Rfc1924) -> "rfc1924-base85"
    Base85(Z85) -> "z85"
    Base91 -> "base91"
  }
}

/// Lowercase the dispatcher's output for encodings whose multibase
/// prefix pins lowercase output (currently `Base16` under prefix `f`).
pub fn normalise_for_multibase_prefix(enc: Encoding, encoded: String) -> String {
  case enc {
    Base16 -> string.lowercase(encoded)
    _ -> encoded
  }
}
