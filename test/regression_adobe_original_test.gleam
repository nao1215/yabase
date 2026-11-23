import yabase as y

pub fn adobe_leading_spaces_test() {
  assert y.decode("  <~v~>", using: y.AdobeAscii85)
    == Error(y.InvalidCharacter("v", 4))
}

pub fn adobe_leading_crlf_test() {
  assert y.decode("\r\n<~v~>", using: y.AdobeAscii85)
    == Error(y.InvalidCharacter("v", 3))
}

pub fn adobe_outer_and_inner_spaces_test() {
  assert y.decode(" <~z v~> ", using: y.AdobeAscii85)
    == Error(y.InvalidCharacter("v", 5))
}

pub fn adobe_body_crlf_control_test() {
  assert y.decode("<~z\r\nv~>", using: y.AdobeAscii85)
    == Error(y.InvalidCharacter("v", 4))
}

pub fn adobe_body_crlf_before_group_control_test() {
  assert y.decode("<~\r\nz v~>", using: y.AdobeAscii85)
    == Error(y.InvalidCharacter("v", 5))
}

pub fn adobe_body_combined_control_test() {
  assert y.decode("<~ź~>", using: y.AdobeAscii85)
    == Error(y.InvalidCharacter("ź", 2))
}

pub fn adobe_delimiter_combined_test() {
  assert y.decode("<~́z~>", using: y.AdobeAscii85)
    == Error(y.InvalidCharacter("~́", 1))
}

pub fn adobe_trim_and_delimiter_combined_test() {
  assert y.decode("  <~́z~>  ", using: y.AdobeAscii85)
    == Error(y.InvalidCharacter("~́", 3))
}

pub fn adobe_combined_before_other_error_test() {
  assert y.decode("<~́!~>", using: y.AdobeAscii85)
    == Error(y.InvalidCharacter("~́", 1))
}

pub fn adobe_overlap_and_empty_controls_test() {
  assert y.decode("<~>", using: y.AdobeAscii85) == Ok(<<>>)
  assert y.decode("<~~>", using: y.AdobeAscii85) == Ok(<<>>)
  assert y.decode("  <~>  ", using: y.AdobeAscii85) == Ok(<<>>)
  assert y.decode("\r\n<~~>\r\n", using: y.AdobeAscii85) == Ok(<<>>)
}
