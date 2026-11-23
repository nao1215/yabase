import codec_test_support
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
import yabase

const byte_aligned: BitArray = <<0xAB>>

pub fn base2_accepts_byte_aligned_test() {
  codec_test_support.encode(byte_aligned, using: yabase.Base2)
  |> should.equal("10101011")
}

pub fn base8_accepts_byte_aligned_test() {
  codec_test_support.encode(byte_aligned, using: yabase.Base8)
  |> should.not_equal("")
}

pub fn base10_accepts_byte_aligned_test() {
  codec_test_support.encode(byte_aligned, using: yabase.Base10)
  |> should.not_equal("")
}

pub fn base16_accepts_byte_aligned_test() {
  codec_test_support.encode(byte_aligned, using: yabase.Base16)
  |> should.equal("AB")
}

pub fn base32_rfc4648_accepts_byte_aligned_test() {
  codec_test_support.encode(byte_aligned, using: yabase.Base32Rfc4648)
  |> should.not_equal("")
}

pub fn base32_hex_accepts_byte_aligned_test() {
  codec_test_support.encode(byte_aligned, using: yabase.Base32Hex)
  |> should.not_equal("")
}

pub fn base32_crockford_accepts_byte_aligned_test() {
  codec_test_support.encode(byte_aligned, using: yabase.Base32Crockford)
  |> should.not_equal("")
}

pub fn base32_clockwork_accepts_byte_aligned_test() {
  codec_test_support.encode(byte_aligned, using: yabase.Base32Clockwork)
  |> should.not_equal("")
}

pub fn base32_zbase32_accepts_byte_aligned_test() {
  codec_test_support.encode(byte_aligned, using: yabase.Zbase32)
  |> should.not_equal("")
}

pub fn base36_accepts_byte_aligned_test() {
  codec_test_support.encode(byte_aligned, using: yabase.Base36)
  |> should.not_equal("")
}

pub fn base45_accepts_byte_aligned_test() {
  codec_test_support.encode(byte_aligned, using: yabase.Base45)
  |> should.not_equal("")
}

pub fn base58_bitcoin_accepts_byte_aligned_test() {
  codec_test_support.encode(byte_aligned, using: yabase.Base58Bitcoin)
  |> should.not_equal("")
}

pub fn base58_flickr_accepts_byte_aligned_test() {
  codec_test_support.encode(byte_aligned, using: yabase.Base58Flickr)
  |> should.not_equal("")
}

pub fn base62_accepts_byte_aligned_test() {
  codec_test_support.encode(byte_aligned, using: yabase.Base62)
  |> should.not_equal("")
}

pub fn base64_standard_accepts_byte_aligned_test() {
  codec_test_support.encode(byte_aligned, using: yabase.Base64)
  |> should.not_equal("")
}

pub fn base64_urlsafe_accepts_byte_aligned_test() {
  codec_test_support.encode(byte_aligned, using: yabase.Base64UrlSafe)
  |> should.not_equal("")
}

pub fn base64_nopadding_accepts_byte_aligned_test() {
  codec_test_support.encode(byte_aligned, using: yabase.Base64NoPadding)
  |> should.not_equal("")
}

pub fn base64_urlsafe_nopadding_accepts_byte_aligned_test() {
  codec_test_support.encode(byte_aligned, using: yabase.Base64UrlSafeNoPadding)
  |> should.not_equal("")
}

pub fn base64_dq_accepts_byte_aligned_test() {
  codec_test_support.encode(byte_aligned, using: yabase.Base64Dq)
  |> should.not_equal("")
}

pub fn base91_accepts_byte_aligned_test() {
  codec_test_support.encode(byte_aligned, using: yabase.Base91)
  |> should.not_equal("")
}

pub fn ascii85_accepts_byte_aligned_test() {
  codec_test_support.encode(byte_aligned, using: yabase.Ascii85)
  |> should.not_equal("")
}

pub fn adobe_ascii85_accepts_byte_aligned_test() {
  codec_test_support.encode(byte_aligned, using: yabase.AdobeAscii85)
  |> should.not_equal("")
}

pub fn empty_input_is_byte_aligned_test() {
  // Zero-bit input is trivially a multiple of 8, so the guard does
  // not reject it. Empty-input behaviour is per-codec; the only
  // thing this test pins is that the guard does not interfere.
  codec_test_support.encode(<<>>, using: yabase.Base16) |> should.equal("")
  codec_test_support.encode(<<>>, using: yabase.Base2) |> should.equal("")
}

// The encoders that already return a Result reject sub-byte input with
// InvalidLength(bit size) instead of dropping the trailing bits.

pub fn z85_rejects_sub_byte_input_test() -> Nil {
  assert yabase.encode(<<1:size(28)>>, using: yabase.Z85)
    == Error(yabase.UnalignedInput(28))
  assert yabase.encode(<<1, 2, 3, 4, 5:size(4)>>, using: yabase.Z85)
    == Error(yabase.UnalignedInput(36))
}

pub fn rfc1924_rejects_sub_byte_input_test() -> Nil {
  assert yabase.encode(<<1:size(28)>>, using: yabase.Rfc1924Base85)
    == Error(yabase.UnalignedInput(28))
}

pub fn base58check_rejects_sub_byte_payload_test() -> Nil {
  assert yabase.encode(<<5:size(3)>>, using: yabase.Base58Check(0))
    == Error(yabase.UnalignedInput(3))
}

pub fn bech32_rejects_sub_byte_data_test() -> Nil {
  assert yabase.encode(
      <<0xFF, 0:size(1)>>,
      using: yabase.Bech32Encoding("a", yabase.Bech32m),
    )
    == Error(yabase.UnalignedInput(9))
  assert yabase.encode(
      <<1:size(3)>>,
      using: yabase.Bech32Encoding("bc", yabase.Bech32),
    )
    == Error(yabase.UnalignedInput(3))
  assert yabase.encode(
      <<1:size(3)>>,
      using: yabase.Bech32Encoding("a", yabase.Bech32m),
    )
    == Error(yabase.UnalignedInput(3))
}
