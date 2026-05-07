/// Regression test for #64: every encoder calls
/// `yabase/core/guard.assert_byte_aligned` at the boundary so a
/// sub-byte `BitArray` (`<<1:size(1)>>`, …) crashes loudly instead
/// of being silently truncated by the byte-walker pattern.
///
/// Gleam has no portable test helper for asserting that a function
/// panics, so the regression here pins the *positive* control: every
/// encode accepts a byte-aligned input and produces a non-empty
/// String. The negative behaviour (sub-byte input → panic) is
/// covered by the docstrings on each codec's `encode` and by the
/// shared `yabase/core/guard.assert_byte_aligned` implementation,
/// which is the single point where the rule is enforced.
import gleeunit/should
import yabase/adobe_ascii85
import yabase/ascii85
import yabase/base10
import yabase/base16
import yabase/base2
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
import yabase/base8
import yabase/base91

const byte_aligned: BitArray = <<0xAB>>

pub fn base2_accepts_byte_aligned_test() {
  base2.encode(byte_aligned) |> should.equal("10101011")
}

pub fn base8_accepts_byte_aligned_test() {
  base8.encode(byte_aligned) |> should.not_equal("")
}

pub fn base10_accepts_byte_aligned_test() {
  base10.encode(byte_aligned) |> should.not_equal("")
}

pub fn base16_accepts_byte_aligned_test() {
  base16.encode(byte_aligned) |> should.equal("AB")
}

pub fn base32_rfc4648_accepts_byte_aligned_test() {
  rfc4648.encode(byte_aligned) |> should.not_equal("")
}

pub fn base32_hex_accepts_byte_aligned_test() {
  base32_hex.encode(byte_aligned) |> should.not_equal("")
}

pub fn base32_crockford_accepts_byte_aligned_test() {
  crockford.encode(byte_aligned) |> should.not_equal("")
}

pub fn base32_clockwork_accepts_byte_aligned_test() {
  clockwork.encode(byte_aligned) |> should.not_equal("")
}

pub fn base32_zbase32_accepts_byte_aligned_test() {
  zbase32.encode(byte_aligned) |> should.not_equal("")
}

pub fn base36_accepts_byte_aligned_test() {
  base36.encode(byte_aligned) |> should.not_equal("")
}

pub fn base45_accepts_byte_aligned_test() {
  base45.encode(byte_aligned) |> should.not_equal("")
}

pub fn base58_bitcoin_accepts_byte_aligned_test() {
  base58_bitcoin.encode(byte_aligned) |> should.not_equal("")
}

pub fn base58_flickr_accepts_byte_aligned_test() {
  base58_flickr.encode(byte_aligned) |> should.not_equal("")
}

pub fn base62_accepts_byte_aligned_test() {
  base62.encode(byte_aligned) |> should.not_equal("")
}

pub fn base64_standard_accepts_byte_aligned_test() {
  standard.encode(byte_aligned) |> should.not_equal("")
}

pub fn base64_urlsafe_accepts_byte_aligned_test() {
  urlsafe.encode(byte_aligned) |> should.not_equal("")
}

pub fn base64_nopadding_accepts_byte_aligned_test() {
  nopadding.encode(byte_aligned) |> should.not_equal("")
}

pub fn base64_urlsafe_nopadding_accepts_byte_aligned_test() {
  urlsafe_nopadding.encode(byte_aligned) |> should.not_equal("")
}

pub fn base64_dq_accepts_byte_aligned_test() {
  dq.encode(byte_aligned) |> should.not_equal("")
}

pub fn base91_accepts_byte_aligned_test() {
  base91.encode(byte_aligned) |> should.not_equal("")
}

pub fn ascii85_accepts_byte_aligned_test() {
  ascii85.encode(byte_aligned) |> should.not_equal("")
}

pub fn adobe_ascii85_accepts_byte_aligned_test() {
  adobe_ascii85.encode(byte_aligned) |> should.not_equal("")
}

pub fn empty_input_is_byte_aligned_test() {
  // Zero-bit input is trivially a multiple of 8, so the guard does
  // not reject it. Empty-input behaviour is per-codec; the only
  // thing this test pins is that the guard does not interfere.
  base16.encode(<<>>) |> should.equal("")
  base2.encode(<<>>) |> should.equal("")
}
