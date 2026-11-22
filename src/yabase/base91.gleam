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
import yabase/core/error.{type CodecError}
import yabase/core/guard
import yabase/internal/alphabet.{type Alphabet}

fn base91() -> Alphabet {
  alphabet.new(
    "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789!#$%&()*+,./:;<=>?@[]^_`{|}~\"",
    alphabet.CaseSensitive,
  )
}

/// Encode a BitArray to Base91.
///
/// Sub-byte input panics; see
/// `yabase/core/guard.assert_byte_aligned`.
pub fn encode(data: BitArray) -> String {
  guard.assert_byte_aligned(data)
  encode_loop(data, base91(), 0, 0, [])
}

fn encode_loop(
  data: BitArray,
  alphabet: Alphabet,
  queue: Int,
  queued: Int,
  acc: List(Int),
) -> String {
  case data {
    <<byte, rest:bytes>> -> {
      let queue = int.bitwise_or(queue, int.bitwise_shift_left(byte, queued))
      let queued = queued + 8
      case queued > 13 {
        True -> {
          let low13 = int.bitwise_and(queue, 8191)
          let #(value, used) = case low13 > 88 {
            True -> #(low13, 13)
            False -> #(int.bitwise_and(queue, 16_383), 14)
          }
          encode_loop(
            rest,
            alphabet,
            int.bitwise_shift_right(queue, used),
            queued - used,
            [
              alphabet.symbol(alphabet, value / 91),
              alphabet.symbol(alphabet, value % 91),
              ..acc
            ],
          )
        }
        False -> encode_loop(rest, alphabet, queue, queued, acc)
      }
    }
    _ -> {
      let acc = case queued > 0 {
        False -> acc
        True ->
          case queued > 7 || queue > 90 {
            True -> [
              alphabet.symbol(alphabet, queue / 91 % 91),
              alphabet.symbol(alphabet, queue % 91),
              ..acc
            ]
            False -> [alphabet.symbol(alphabet, queue % 91), ..acc]
          }
      }
      alphabet.to_string(list.reverse(acc))
    }
  }
}

/// Decode a Base91 string to a BitArray.
pub fn decode(input: String) -> Result(BitArray, CodecError) {
  let bytes = bit_array.from_string(input)
  decode_loop(
    Decoder(input: bytes, alphabet: base91()),
    bytes,
    0,
    0,
    -1,
    0,
    0,
    [],
  )
}

type Decoder {
  Decoder(input: BitArray, alphabet: Alphabet)
}

fn decode_loop(
  decoder: Decoder,
  rest: BitArray,
  offset: Int,
  position: Int,
  pending: Int,
  queue: Int,
  queued: Int,
  acc: List(BitArray),
) -> Result(BitArray, CodecError) {
  case rest {
    // The basE91 reference decoder ignores characters outside the
    // alphabet; this one only skips ASCII whitespace, so wrapped output
    // decodes. CR LF counts as one position, like one character.
    <<13, 10, rest:bytes>> ->
      decode_loop(
        decoder,
        rest,
        offset + 2,
        position + 1,
        pending,
        queue,
        queued,
        acc,
      )
    <<byte, rest:bytes>>
      if byte == 32 || byte == 9 || byte == 10 || byte == 13
    ->
      decode_loop(
        decoder,
        rest,
        offset + 1,
        position + 1,
        pending,
        queue,
        queued,
        acc,
      )
    <<byte, rest:bytes>> ->
      case alphabet.lookup(decoder.alphabet, byte) {
        alphabet.Value(digit) if pending == -1 ->
          decode_loop(
            decoder,
            rest,
            offset + 1,
            position + 1,
            digit,
            queue,
            queued,
            acc,
          )
        alphabet.Value(digit) -> {
          let value = pending + digit * 91
          let used = case int.bitwise_and(value, 8191) > 88 {
            True -> 13
            False -> 14
          }
          let queue =
            int.bitwise_or(queue, int.bitwise_shift_left(value, queued))
          let #(queue, queued, acc) = flush_bytes(queue, queued + used, acc)
          decode_loop(
            decoder,
            rest,
            offset + 1,
            position + 1,
            -1,
            queue,
            queued,
            acc,
          )
        }
        alphabet.Ignored | alphabet.Invalid ->
          Error(alphabet.invalid_character(
            decoder.alphabet,
            decoder.input,
            offset,
            position,
          ))
      }
    _ -> {
      // Flush one final byte from the remaining bits, as the C reference
      // does.
      let acc = case pending {
        -1 -> acc
        _ -> {
          let last =
            int.bitwise_or(queue, int.bitwise_shift_left(pending, queued))
          [<<{ int.bitwise_and(last, 255) }>>, ..acc]
        }
      }
      Ok(bit_array.concat(list.reverse(acc)))
    }
  }
}

fn flush_bytes(
  queue: Int,
  queued: Int,
  acc: List(BitArray),
) -> #(Int, Int, List(BitArray)) {
  use <- bool.guard(when: queued < 8, return: #(queue, queued, acc))
  flush_bytes(int.bitwise_shift_right(queue, 8), queued - 8, [
    <<{ int.bitwise_and(queue, 255) }>>,
    ..acc
  ])
}
