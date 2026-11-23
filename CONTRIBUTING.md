# Contributing

Report bugs with a small input, the expected result, the actual error or output,
and your yabase, Gleam and runtime versions. Check existing issues before
proposing a new encoding or changing an accepted wire format.

## Development

Use Gleam 1.15 or later, Erlang/OTP 26 or later, Node.js 18 or later, and
[just](https://just.systems/). [mise](https://mise.jdx.dev/) can install the
versions in `.mise.toml`.

```sh
git clone https://github.com/nao1215/yabase.git
cd yabase
mise install
just ci
gleam build --target javascript --warnings-as-errors
gleam test --target javascript
```

`just ci` downloads dependencies and checks formatting, lint, the Erlang build,
tests, examples and README code blocks. Run the JavaScript commands too when
changing codec behavior. The GitHub workflows test the supported compiler and
runtime versions. `just gen-readme` prints the multibase table; paste it between
the existing markers in README when registry entries change.

## API and implementation

The public API lives in `src/yabase.gleam`. Select codecs through `Encoding` and
use the subject-first encoding and decoding functions. Encoders return
`Result(String, CodecError)`; byte decoders return bytes or a metadata record.
Public records expose decoded metadata directly. Add a public type or function
only when it expresses behavior that the existing operations cannot express.

Implementation helpers remain private. The SHA-256 implementation is an
internal module. Prefer Gleam and standard-library operations over new runtime
dependencies or FFI. Keep byte operations independent of the host integer
range, preserve leading zeros, and keep intermediate arithmetic exact on both
targets.

When adding an encoding, document its alphabet, padding, metadata and accepted
noncanonical forms. Add its `Encoding` variant and dispatch, then a multibase
entry if the registry assigns one. Include independent wire vectors, malformed
input, partial-byte input and leading-zero tests. A matching encoder/decoder
round trip alone cannot establish conformance.

## Tests and documentation

Write a reproducing test before fixing a bug. Preserve the original character
and grapheme position in decoding errors, including ignored separators and
multibase prefixes. Combined invalid inputs should verify which validation
stage wins. Integer decoding must check syntax, metadata, target range and
canonical representation before an explicit upper bound.

Document public functions, types, variants and constants. Give executable
examples with literal expected output. Update README examples and the generated
prefix table when their public calls change; keep detailed contracts in the
API reference. [Testing](doc/testing.md) describes the suite and its oracles.

## Pull requests

Describe the behavior change, its reason, and the checks you ran. Include
reproductions for defects and name any public contract that changes. All CI
checks must pass before merge. Review generated code and documentation as you
would any other contribution.

## License

Contributions are released under the [MIT license](LICENSE).
