//// Lookup tables for the ASCII alphabets the codecs share.
////
//// Decoders read their input as bytes (`bit_array.from_string`) and look
//// each byte up in a 256-entry table, so a decode costs one table read per
//// character on both targets. Non-ASCII bytes never match, which means a
//// letter only folds to its other case when both forms are ASCII.

import gleam/bit_array
import gleam/dict.{type Dict}
import gleam/list
import gleam/result
import gleam/string
import yabase/core/error.{type CodecError, InvalidCharacter}

/// How a decoder treats letter case.
pub type Folding {
  /// Only the symbols themselves are accepted.
  CaseSensitive
  /// Both cases are accepted; a rejected letter is reported in upper case.
  FoldToUpper
  /// Both cases are accepted; a rejected letter is reported in lower case.
  FoldToLower
}

pub opaque type Alphabet {
  Alphabet(symbols: BitArray, values: BitArray, folding: Folding)
}

/// Marks a byte that is not part of the alphabet.
const invalid = 255

/// Marks a byte the decoder drops without counting it as a character.
const ignored = 254

/// Build an alphabet whose symbol for value `i` is the `i`-th byte of
/// `symbols`.
pub fn new(symbols: String, folding: Folding) -> Alphabet {
  with_extras(symbols:, folding:, aliases: [], ignore: "")
}

/// Like `new`, but `aliases` adds extra accepted characters for a value and
/// `ignore` lists characters the decoder skips without counting them.
pub fn with_extras(
  symbols symbols: String,
  folding folding: Folding,
  aliases aliases: List(#(String, Int)),
  ignore ignore: String,
) -> Alphabet {
  let symbol_bytes = bit_array.from_string(symbols)
  let entries =
    list.index_map(string.to_graphemes(symbols), fn(symbol, value) {
      #(symbol, value)
    })
    |> list.append(aliases)
    |> list.flat_map(fn(entry) {
      let #(symbol, value) = entry
      case folding {
        CaseSensitive -> [#(symbol, value)]
        FoldToUpper | FoldToLower -> [
          #(string.uppercase(symbol), value),
          #(string.lowercase(symbol), value),
        ]
      }
    })
    |> list.append(
      list.map(string.to_graphemes(ignore), fn(symbol) { #(symbol, ignored) }),
    )
  let table =
    list.fold(entries, dict.new(), fn(table, entry) {
      case bit_array.from_string(entry.0) {
        <<byte>> -> dict.insert(table, byte, entry.1)
        _ -> table
      }
    })
  Alphabet(
    symbols: symbol_bytes,
    values: build_values(table, 255, []),
    folding: folding,
  )
}

fn build_values(
  table: Dict(Int, Int),
  byte: Int,
  acc: List(BitArray),
) -> BitArray {
  case byte < 0 {
    True -> bit_array.concat(acc)
    False -> {
      let value = case dict.get(table, byte) {
        Ok(value) -> value
        Error(Nil) -> invalid
      }
      build_values(table, byte - 1, [<<value>>, ..acc])
    }
  }
}

/// Number of symbols, which is the radix of the alphabet.
pub fn size(alphabet: Alphabet) -> Int {
  bit_array.byte_size(alphabet.symbols)
}

/// The symbol byte for `value`. `value` must be below `size(alphabet)`.
pub fn symbol(alphabet: Alphabet, value: Int) -> Int {
  case alphabet.symbols {
    <<_:bytes-size(value), byte, _:bits>> -> byte
    // Callers only pass values below the radix.
    _ -> 0
  }
}

/// What a byte means to the decoder.
pub type Lookup {
  Value(Int)
  Ignored
  Invalid
}

/// Look up one input byte.
pub fn lookup(alphabet: Alphabet, byte: Int) -> Lookup {
  case alphabet.values {
    <<_:bytes-size(byte), value, _:bits>> ->
      case value {
        _ if value == invalid -> Invalid
        _ if value == ignored -> Ignored
        _ -> Value(value)
      }
    _ -> Invalid
  }
}

/// The error for the character that starts at byte `offset` of `input`,
/// which is character number `position`. Every byte before `offset` must be
/// ASCII, so `offset` starts a UTF-8 sequence.
pub fn invalid_character(
  alphabet: Alphabet,
  input: BitArray,
  offset: Int,
  position: Int,
) -> CodecError {
  InvalidCharacter(
    report(character_at(input, offset), alphabet.folding),
    position,
  )
}

fn character_at(input: BitArray, offset: Int) -> String {
  let found = {
    use rest <- result.try(bit_array.slice(
      input,
      offset,
      bit_array.byte_size(input) - offset,
    ))
    use text <- result.try(bit_array.to_string(rest))
    string.pop_grapheme(text)
  }
  case found {
    Ok(#(character, _)) -> character
    Error(Nil) -> ""
  }
}

fn report(character: String, folding: Folding) -> String {
  case folding, bit_array.from_string(character) {
    CaseSensitive, _ -> character
    FoldToUpper, <<_>> -> string.uppercase(character)
    FoldToLower, <<_>> -> string.lowercase(character)
    _, _ -> character
  }
}

/// Join symbol bytes, given most significant first, into a string.
pub fn to_string(symbols: List(Int)) -> String {
  symbols
  |> list.map(fn(byte) { <<byte>> })
  |> chunks_to_string
}

/// Join chunks of symbol bytes into a string. The chunks hold only
/// alphabet symbols, which are ASCII.
pub fn chunks_to_string(chunks: List(BitArray)) -> String {
  case bit_array.to_string(bit_array.concat(chunks)) {
    Ok(text) -> text
    Error(Nil) -> ""
  }
}

/// Characters (graphemes) in `input`, whose bytes are `bytes`. ASCII
/// without CR has one character per byte, so only other input needs the
/// slower `string.length`.
pub fn character_count(input: String, bytes: BitArray) -> Int {
  case plain_ascii(bytes) {
    True -> bit_array.byte_size(bytes)
    False -> string.length(input)
  }
}

fn plain_ascii(bytes: BitArray) -> Bool {
  case bytes {
    <<byte, rest:bytes>> if byte < 128 && byte != 13 -> plain_ascii(rest)
    <<_, _:bytes>> -> False
    _ -> True
  }
}
