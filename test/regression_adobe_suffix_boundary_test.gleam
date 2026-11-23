import yabase

pub fn suffix_boundary_after_prepend_grapheme_test() {
  // U+0600 has Grapheme_Cluster_Break=Prepend. The retained U+0600 and
  // trimmed SPACE belong to the fourth original grapheme.
  assert yabase.decode("<~z\u{0600} ", using: yabase.AdobeAscii85)
    == Error(yabase.MissingDelimiter("~>", 4))
}

pub fn suffix_boundary_after_prepend_with_outer_trim_test() {
  assert yabase.decode("  <~z\u{0600} \r\n", using: yabase.AdobeAscii85)
    == Error(yabase.MissingDelimiter("~>", 6))
}

pub fn suffix_boundary_before_trailing_crlf_test() {
  // The insertion boundary follows U+0600's cluster, not the original EOF.
  assert yabase.decode("<~z\u{0600} \r\n", using: yabase.AdobeAscii85)
    == Error(yabase.MissingDelimiter("~>", 4))
}

pub fn suffix_boundary_control_before_tab_test() {
  // TAB breaks the cluster, so this boundary is already exact.
  assert yabase.decode("<~z\u{0600}\t", using: yabase.AdobeAscii85)
    == Error(yabase.MissingDelimiter("~>", 4))
}

pub fn empty_trim_span_uses_original_eof_control_test() {
  assert yabase.decode(" \r\n", using: yabase.AdobeAscii85)
    == Error(yabase.MissingDelimiter("<~", 2))
}
