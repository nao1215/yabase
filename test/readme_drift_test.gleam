import gleam/bool
import gleam/string
import simplifile
import yabase/internal/readme_table

@target(erlang)
/// The README declares a fenced section for the multibase prefix
/// table. The bytes between BEGIN/END must equal what
/// `readme_table.multibase_prefix_table/0` returns. If a contributor
/// adds or changes a multibase mapping in `yabase/core/encoding`,
/// this test will fail until the README is regenerated (via
/// `just gen-readme`).
///
/// BEAM-only: the test reads `README.md` from the working directory,
/// which is meaningful only in a development checkout. Running this
/// on the JavaScript target would just exercise simplifile's Node.js
/// path with no extra coverage.
pub fn multibase_prefix_table_matches_readme_test() -> Nil {
  let assert Ok(readme) = simplifile.read("README.md")

  let assert Ok(after_begin) =
    split_after(readme, readme_table.multibase_prefix_table_begin)
  let assert Ok(section) =
    split_before(after_begin, readme_table.multibase_prefix_table_end)

  let canonical = trim_newlines(readme_table.multibase_prefix_table())
  let actual = trim_newlines(section)
  assert actual == canonical
}

fn split_after(input: String, marker: String) -> Result(String, Nil) {
  case string.split_once(input, marker) {
    Ok(#(_before, after)) -> Ok(after)
    Error(Nil) -> Error(Nil)
  }
}

fn split_before(input: String, marker: String) -> Result(String, Nil) {
  case string.split_once(input, marker) {
    Ok(#(before, _after)) -> Ok(before)
    Error(Nil) -> Error(Nil)
  }
}

/// Strip every leading and trailing newline. Both the canonical
/// render (which terminates with `\n`) and the README section
/// (which has blank lines after BEGIN and before END for human
/// readability) get normalised to the same naked-rows shape, so the
/// comparison only fails on substantive differences.
fn trim_newlines(input: String) -> String {
  trim_trailing_newlines(trim_leading_newlines(input))
}

fn trim_leading_newlines(input: String) -> String {
  case input {
    "\n" <> rest -> trim_leading_newlines(rest)
    _ -> input
  }
}

fn trim_trailing_newlines(input: String) -> String {
  use <- bool.guard(when: !string.ends_with(input, "\n"), return: input)
  trim_trailing_newlines(string.drop_end(input, 1))
}
