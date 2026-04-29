/// Base91 encoding.
/// Uses 91 printable ASCII characters for efficient binary-to-text encoding.
/// More space-efficient than Base64 (roughly 23% overhead vs 33%).
///
/// Based on the algorithm by Joachim Henke. The bitwise queue arithmetic
/// uses `gleam/int.bitwise_*` so the implementation runs identically on
/// Erlang and JavaScript targets.
import gleam/bit_array
import gleam/bool
import gleam/int
import gleam/list
import gleam/string
import yabase/core/error.{type CodecError, InvalidCharacter}

const alphabet = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789!#$%&()*+,./:;<=>?@[]^_`{|}~\""

/// Encode a BitArray to Base91.
pub fn encode(data: BitArray) -> String {
  encode_loop(data, 0, 0, [])
  |> list.reverse
  |> string.join("")
}

fn encode_loop(
  data: BitArray,
  queue: Int,
  nbits: Int,
  acc: List(String),
) -> List(String) {
  case data {
    <<byte:8, rest:bits>> -> {
      let new_queue = bor(queue, bsl(byte, nbits))
      let new_nbits = nbits + 8
      case new_nbits > 13 {
        True -> {
          let val = band(new_queue, 8191)
          case val > 88 {
            True -> {
              let c1 = char_at(val % 91)
              let c2 = char_at(val / 91)
              encode_loop(rest, bsr(new_queue, 13), new_nbits - 13, [
                c1 <> c2,
                ..acc
              ])
            }
            False -> {
              let val2 = band(new_queue, 16_383)
              let c1 = char_at(val2 % 91)
              let c2 = char_at(val2 / 91)
              encode_loop(rest, bsr(new_queue, 14), new_nbits - 14, [
                c1 <> c2,
                ..acc
              ])
            }
          }
        }
        False -> encode_loop(rest, new_queue, new_nbits, acc)
      }
    }
    _ -> {
      case nbits > 0 {
        True -> {
          let c1 = char_at(queue % 91)
          case nbits > 7 || queue > 90 {
            True -> [c1 <> char_at({ queue / 91 } % 91), ..acc]
            False -> [c1, ..acc]
          }
        }
        False -> acc
      }
    }
  }
}

/// Decode a Base91 string to a BitArray.
pub fn decode(input: String) -> Result(BitArray, CodecError) {
  decode_loop(string.to_graphemes(input), -1, 0, 0, [], 0)
}

fn decode_loop(
  chars: List(String),
  val: Int,
  queue: Int,
  nbits: Int,
  acc: List(Int),
  pos: Int,
) -> Result(BitArray, CodecError) {
  case chars {
    [] -> {
      let final_acc = case val != -1 {
        True -> {
          // Flush one final byte from remaining bits (matches C reference)
          let combined = bor(queue, bsl(val, nbits))
          [band(combined, 255), ..acc]
        }
        False -> acc
      }
      Ok(list_to_bit_array(list.reverse(final_acc), <<>>))
    }
    [c, ..rest] ->
      case char_index(c) {
        Error(Nil) -> Error(InvalidCharacter(c, pos))
        Ok(d) ->
          case val == -1 {
            True -> decode_loop(rest, d, queue, nbits, acc, pos + 1)
            False -> {
              let combined = val + d * 91
              let bits_to_consume = case band(combined, 8191) > 88 {
                True -> 13
                False -> 14
              }
              let new_queue = bor(queue, bsl(combined, nbits))
              let new_nbits = nbits + bits_to_consume
              let new_acc = extract_bytes_from_queue(new_queue, new_nbits, acc)
              let consumed = new_nbits / 8
              let remaining_nbits = new_nbits - consumed * 8
              decode_loop(
                rest,
                -1,
                bsr(new_queue, consumed * 8),
                remaining_nbits,
                new_acc,
                pos + 1,
              )
            }
          }
      }
  }
}

fn extract_bytes_from_queue(queue: Int, nbits: Int, acc: List(Int)) -> List(Int) {
  use <- bool.guard(when: nbits < 8, return: acc)
  extract_bytes_from_queue(bsr(queue, 8), nbits - 8, [band(queue, 255), ..acc])
}

// Cross-target bitwise wrappers around gleam/int.
fn bor(a: Int, b: Int) -> Int {
  int.bitwise_or(a, b)
}

fn band(a: Int, b: Int) -> Int {
  int.bitwise_and(a, b)
}

fn bsl(a: Int, b: Int) -> Int {
  int.bitwise_shift_left(a, b)
}

fn bsr(a: Int, b: Int) -> Int {
  int.bitwise_shift_right(a, b)
}

fn char_at(index: Int) -> String {
  case string.drop_start(alphabet, index) |> string.pop_grapheme {
    Ok(#(c, _)) -> c
    Error(Nil) -> ""
  }
}

fn char_index(c: String) -> Result(Int, Nil) {
  find_in_graphemes(string.to_graphemes(alphabet), c, 0)
}

fn find_in_graphemes(
  haystack: List(String),
  needle: String,
  idx: Int,
) -> Result(Int, Nil) {
  case haystack {
    [] -> Error(Nil)
    [h, ..rest] ->
      case h == needle {
        True -> Ok(idx)
        False -> find_in_graphemes(rest, needle, idx + 1)
      }
  }
}

fn list_to_bit_array(bytes: List(Int), acc: BitArray) -> BitArray {
  case bytes {
    [] -> acc
    [b, ..rest] -> list_to_bit_array(rest, bit_array.append(acc, <<b:int>>))
  }
}
