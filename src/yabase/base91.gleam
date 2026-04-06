/// Base91 encoding.
/// Uses 91 printable ASCII characters for efficient binary-to-text encoding.
/// More space-efficient than Base64 (roughly 23% overhead vs 33%).
import gleam/bit_array
import gleam/string
import yabase/core/encoding.{type CodecError, InvalidCharacter}

const alphabet = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789!#$%&()*+,./:;<=>?@[]^_`{|}~\""

/// Encode a BitArray to Base91.
pub fn encode(data: BitArray) -> String {
  encode_loop(data, 0, 0, "")
}

fn encode_loop(data: BitArray, queue: Int, nbits: Int, acc: String) -> String {
  case data {
    <<byte:8, rest:bits>> -> {
      let new_queue = queue + shift_left(byte, nbits)
      let new_nbits = nbits + 8
      case new_nbits > 13 {
        True -> {
          let val = new_queue % 8192
          case val > 88 {
            True -> {
              let c1 = char_at(val % 91)
              let c2 = char_at(val / 91)
              encode_loop(
                rest,
                shift_right(new_queue, 13),
                new_nbits - 13,
                acc <> c1 <> c2,
              )
            }
            False -> {
              let val2 = new_queue % 91
              let c1 = char_at(val2)
              let c2 = char_at({ new_queue / 91 } % 91)
              encode_loop(
                rest,
                shift_right(new_queue, 14),
                new_nbits - 14,
                acc <> c1 <> c2,
              )
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
            True -> acc <> c1 <> char_at({ queue / 91 } % 91)
            False -> acc <> c1
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
          let combined_queue = queue + shift_left(val, nbits)
          let combined_nbits = nbits + 7
          extract_bytes_from_queue(combined_queue, combined_nbits, acc)
        }
        False -> acc
      }
      Ok(list_to_bit_array(list_reverse(final_acc), <<>>))
    }
    [c, ..rest] ->
      case char_index(c) {
        Error(_) -> Error(InvalidCharacter(c, pos))
        Ok(d) ->
          case val == -1 {
            True -> decode_loop(rest, d, queue, nbits, acc, pos + 1)
            False -> {
              let combined = val + d * 91
              let bits_to_consume = case combined % 8192 > 88 {
                True -> 13
                False -> 14
              }
              let new_queue = queue + shift_left(combined, nbits)
              let new_nbits = nbits + bits_to_consume
              let new_acc = extract_bytes_from_queue(new_queue, new_nbits, acc)
              let consumed = count_whole_bytes(new_nbits)
              decode_loop(
                rest,
                -1,
                shift_right(new_queue, consumed * 8),
                new_nbits - consumed * 8,
                new_acc,
                pos + 1,
              )
            }
          }
      }
  }
}

fn count_whole_bytes(nbits: Int) -> Int {
  nbits / 8
}

fn extract_bytes_from_queue(queue: Int, nbits: Int, acc: List(Int)) -> List(Int) {
  case nbits >= 8 {
    True ->
      extract_bytes_from_queue(shift_right(queue, 8), nbits - 8, [
        queue % 256,
        ..acc
      ])
    False -> acc
  }
}

fn shift_left(n: Int, bits: Int) -> Int {
  case bits {
    0 -> n
    _ -> shift_left(n * 2, bits - 1)
  }
}

fn shift_right(n: Int, bits: Int) -> Int {
  case bits {
    0 -> n
    _ -> shift_right(n / 2, bits - 1)
  }
}

fn char_at(index: Int) -> String {
  case string.drop_start(alphabet, index) |> string.pop_grapheme {
    Ok(#(c, _)) -> c
    Error(_) -> ""
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

fn list_reverse(l: List(Int)) -> List(Int) {
  list_reverse_acc(l, [])
}

fn list_reverse_acc(l: List(Int), acc: List(Int)) -> List(Int) {
  case l {
    [] -> acc
    [h, ..t] -> list_reverse_acc(t, [h, ..acc])
  }
}

fn list_to_bit_array(bytes: List(Int), acc: BitArray) -> BitArray {
  case bytes {
    [] -> acc
    [b, ..rest] -> list_to_bit_array(rest, bit_array.append(acc, <<b:int>>))
  }
}
