/// Unified encode/decode dispatch via the Encoding type.
import yabase/adobe_ascii85
import yabase/ascii85
import yabase/base16
import yabase/base32/clockwork
import yabase/base32/crockford
import yabase/base32/hex as base32_hex
import yabase/base32/rfc4648 as base32_rfc4648
import yabase/base32/zbase32
import yabase/base36
import yabase/base45
import yabase/base58
import yabase/base62
import yabase/base64/dq as base64_dq
import yabase/base64/nopadding as base64_nopadding
import yabase/base64/standard as base64_standard
import yabase/base64/urlsafe as base64_urlsafe
import yabase/base64/urlsafe_nopadding as base64_urlsafe_nopadding
import yabase/base91
import yabase/core/encoding.{
  type CodecError, type Encoding, AdobeAscii85 as AdobeAscii85Encoding,
  Ascii85 as Ascii85Encoding, Base16 as Base16Encoding, Base32 as Base32Encoding,
  Base36 as Base36Encoding, Base45 as Base45Encoding, Base58 as Base58Encoding,
  Base62 as Base62Encoding, Base64 as Base64Encoding, Base91 as Base91Encoding,
  Clockwork, Crockford, DQ, Hex, NoPadding, RFC4648,
  Rfc1924Base85 as Rfc1924Encoding, Standard, UrlSafe, UrlSafeNoPadding,
  Z85 as Z85Encoding, ZBase32,
}
import yabase/rfc1924_base85
import yabase/z85

/// Encode data using the specified encoding.
/// Returns Result because some encodings have input length constraints.
pub fn encode(enc: Encoding, data: BitArray) -> Result(String, CodecError) {
  case enc {
    Base16Encoding -> Ok(base16.encode(data))
    Base32Encoding(RFC4648) -> Ok(base32_rfc4648.encode(data))
    Base32Encoding(Hex) -> Ok(base32_hex.encode(data))
    Base32Encoding(Crockford) -> Ok(crockford.encode(data))
    Base32Encoding(Clockwork) -> Ok(clockwork.encode(data))
    Base32Encoding(ZBase32) -> Ok(zbase32.encode(data))
    Base36Encoding -> Ok(base36.encode(data))
    Base45Encoding -> Ok(base45.encode(data))
    Base58Encoding -> Ok(base58.encode(data))
    Base62Encoding -> Ok(base62.encode(data))
    Base64Encoding(Standard) -> Ok(base64_standard.encode(data))
    Base64Encoding(UrlSafe) -> Ok(base64_urlsafe.encode(data))
    Base64Encoding(NoPadding) -> Ok(base64_nopadding.encode(data))
    Base64Encoding(UrlSafeNoPadding) ->
      Ok(base64_urlsafe_nopadding.encode(data))
    Base64Encoding(DQ) -> Ok(base64_dq.encode(data))
    Base91Encoding -> Ok(base91.encode(data))
    Ascii85Encoding -> Ok(ascii85.encode(data))
    AdobeAscii85Encoding -> Ok(adobe_ascii85.encode(data))
    Rfc1924Encoding -> rfc1924_base85.encode(data)
    Z85Encoding -> z85.encode(data)
  }
}

/// Decode data using the specified encoding.
pub fn decode_as(enc: Encoding, value: String) -> Result(BitArray, CodecError) {
  case enc {
    Base16Encoding -> base16.decode(value)
    Base32Encoding(RFC4648) -> base32_rfc4648.decode(value)
    Base32Encoding(Hex) -> base32_hex.decode(value)
    Base32Encoding(Crockford) -> crockford.decode(value)
    Base32Encoding(Clockwork) -> clockwork.decode(value)
    Base32Encoding(ZBase32) -> zbase32.decode(value)
    Base36Encoding -> base36.decode(value)
    Base45Encoding -> base45.decode(value)
    Base58Encoding -> base58.decode(value)
    Base62Encoding -> base62.decode(value)
    Base64Encoding(Standard) -> base64_standard.decode(value)
    Base64Encoding(UrlSafe) -> base64_urlsafe.decode(value)
    Base64Encoding(NoPadding) -> base64_nopadding.decode(value)
    Base64Encoding(UrlSafeNoPadding) -> base64_urlsafe_nopadding.decode(value)
    Base64Encoding(DQ) -> base64_dq.decode(value)
    Base91Encoding -> base91.decode(value)
    Ascii85Encoding -> ascii85.decode(value)
    AdobeAscii85Encoding -> adobe_ascii85.decode(value)
    Rfc1924Encoding -> rfc1924_base85.decode(value)
    Z85Encoding -> z85.decode(value)
  }
}
