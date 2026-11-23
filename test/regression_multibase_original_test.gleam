import yabase as y

pub fn multibase_hex_payload_test() {
  assert y.decode_multibase("f0!") == Error(y.InvalidCharacter("!", 2))
}

pub fn multibase_combined_payload_test() {
  assert y.decode_multibase("fÁ0") == Error(y.InvalidCharacter("Á", 1))
}

pub fn multibase_base64_payload_test() {
  assert y.decode_multibase("mQQ!D") == Error(y.InvalidCharacter("!", 3))
}

pub fn multibase_octal_payload_test() {
  assert y.decode_multibase("7!") == Error(y.InvalidCharacter("!", 1))
}
