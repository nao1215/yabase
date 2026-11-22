/// Pure Gleam SHA-256 implementation.
/// Used only for checksum computation in Base58Check.
import gleam/bit_array
import gleam/int
import gleam/list

/// Compute SHA-256 hash of data. Returns a 32-byte BitArray.
pub fn hash(data: BitArray) -> BitArray {
  let padded = pad_message(data)
  let state = initial_hash()
  process_blocks(padded, state)
  |> state_to_bytes
}

// Initial hash values (first 32 bits of fractional parts of sqrt of first 8 primes)
fn initial_hash() -> #(Int, Int, Int, Int, Int, Int, Int, Int) {
  #(
    0x6a09e667,
    0xbb67ae85,
    0x3c6ef372,
    0xa54ff53a,
    0x510e527f,
    0x9b05688c,
    0x1f83d9ab,
    0x5be0cd19,
  )
}

// Round constants (first 32 bits of fractional parts of cube roots of first 64 primes)
fn round_constant(i: Int) -> Int {
  case i {
    0 -> 0x428a2f98
    1 -> 0x71374491
    2 -> 0xb5c0fbcf
    3 -> 0xe9b5dba5
    4 -> 0x3956c25b
    5 -> 0x59f111f1
    6 -> 0x923f82a4
    7 -> 0xab1c5ed5
    8 -> 0xd807aa98
    9 -> 0x12835b01
    10 -> 0x243185be
    11 -> 0x550c7dc3
    12 -> 0x72be5d74
    13 -> 0x80deb1fe
    14 -> 0x9bdc06a7
    15 -> 0xc19bf174
    16 -> 0xe49b69c1
    17 -> 0xefbe4786
    18 -> 0x0fc19dc6
    19 -> 0x240ca1cc
    20 -> 0x2de92c6f
    21 -> 0x4a7484aa
    22 -> 0x5cb0a9dc
    23 -> 0x76f988da
    24 -> 0x983e5152
    25 -> 0xa831c66d
    26 -> 0xb00327c8
    27 -> 0xbf597fc7
    28 -> 0xc6e00bf3
    29 -> 0xd5a79147
    30 -> 0x06ca6351
    31 -> 0x14292967
    32 -> 0x27b70a85
    33 -> 0x2e1b2138
    34 -> 0x4d2c6dfc
    35 -> 0x53380d13
    36 -> 0x650a7354
    37 -> 0x766a0abb
    38 -> 0x81c2c92e
    39 -> 0x92722c85
    40 -> 0xa2bfe8a1
    41 -> 0xa81a664b
    42 -> 0xc24b8b70
    43 -> 0xc76c51a3
    44 -> 0xd192e819
    45 -> 0xd6990624
    46 -> 0xf40e3585
    47 -> 0x106aa070
    48 -> 0x19a4c116
    49 -> 0x1e376c08
    50 -> 0x2748774c
    51 -> 0x34b0bcb5
    52 -> 0x391c0cb3
    53 -> 0x4ed8aa4a
    54 -> 0x5b9cca4f
    55 -> 0x682e6ff3
    56 -> 0x748f82ee
    57 -> 0x78a5636f
    58 -> 0x84c87814
    59 -> 0x8cc70208
    60 -> 0x90befffa
    61 -> 0xa4506ceb
    62 -> 0xbef9a3f7
    63 -> 0xc67178f2
    _ -> 0
  }
}

// JavaScript bitwise operators return signed 32-bit values. Normalize sums
// modulo 2^32, and mask sign extension when shifting right.
fn mask32(value: Int) -> Int {
  let remainder = value % 4_294_967_296
  case remainder < 0 {
    True -> remainder + 4_294_967_296
    False -> remainder
  }
}

fn shift_right(value: Int, amount: Int) -> Int {
  int.bitwise_and(
    int.bitwise_shift_right(value, amount),
    int.bitwise_shift_right(0x7FFFFFFF, amount - 1),
  )
}

fn rotate_right(value: Int, amount: Int) -> Int {
  int.bitwise_or(
    shift_right(value, amount),
    int.bitwise_shift_left(
      int.bitwise_and(value, int.bitwise_shift_left(1, amount) - 1),
      32 - amount,
    ),
  )
}

fn add32(left: Int, right: Int) -> Int {
  mask32(left + right)
}

// SHA-256 functions
fn choose(x: Int, y: Int, z: Int) -> Int {
  int.bitwise_exclusive_or(
    int.bitwise_and(x, y),
    int.bitwise_and(int.bitwise_not(x), z),
  )
}

fn majority(x: Int, y: Int, z: Int) -> Int {
  int.bitwise_exclusive_or(
    int.bitwise_exclusive_or(int.bitwise_and(x, y), int.bitwise_and(x, z)),
    int.bitwise_and(y, z),
  )
}

fn big_sigma0(x: Int) -> Int {
  int.bitwise_exclusive_or(
    int.bitwise_exclusive_or(rotate_right(x, 2), rotate_right(x, 13)),
    rotate_right(x, 22),
  )
}

fn big_sigma1(x: Int) -> Int {
  int.bitwise_exclusive_or(
    int.bitwise_exclusive_or(rotate_right(x, 6), rotate_right(x, 11)),
    rotate_right(x, 25),
  )
}

fn small_sigma0(x: Int) -> Int {
  int.bitwise_exclusive_or(
    int.bitwise_exclusive_or(rotate_right(x, 7), rotate_right(x, 18)),
    shift_right(x, 3),
  )
}

fn small_sigma1(x: Int) -> Int {
  int.bitwise_exclusive_or(
    int.bitwise_exclusive_or(rotate_right(x, 17), rotate_right(x, 19)),
    shift_right(x, 10),
  )
}

// Message padding: append 1 bit, pad zeros, append 64-bit big-endian length
fn pad_message(data: BitArray) -> BitArray {
  let bit_length = bit_array.byte_size(data) * 8
  let high = bit_length / 4_294_967_296
  let low = bit_length % 4_294_967_296
  let zeros = { 55 - bit_array.byte_size(data) % 64 + 64 } % 64
  bit_array.concat([data, <<0x80>>, <<0:size(zeros * 8)>>, <<high:32, low:32>>])
}

fn process_blocks(
  data: BitArray,
  state: #(Int, Int, Int, Int, Int, Int, Int, Int),
) -> #(Int, Int, Int, Int, Int, Int, Int, Int) {
  case data {
    <<block:bytes-size(64), rest:bytes>> ->
      process_blocks(rest, compress(state, parse_block(block)))
    _ -> state
  }
}

// Parse 64-byte block into 16 32-bit words, then expand to 64 words
fn parse_block(block: BitArray) -> List(Int) {
  let words = parse_words(block, [])
  expand_schedule(words, 16)
}

fn parse_words(data: BitArray, words: List(Int)) -> List(Int) {
  case data {
    <<word:32, rest:bytes>> -> parse_words(rest, [word, ..words])
    _ -> words
  }
}

// The newest word is at the head, so all four lookups have fixed offsets.
fn expand_schedule(words: List(Int), count: Int) -> List(Int) {
  case count, words {
    64, _ -> list.reverse(words)
    _, [_, word2, _, _, _, _, word7, _, _, _, _, _, _, _, word15, word16, ..] -> {
      let word =
        add32(
          add32(small_sigma1(word2), word7),
          add32(small_sigma0(word15), word16),
        )
      expand_schedule([word, ..words], count + 1)
    }
    _, _ -> list.reverse(words)
  }
}

// 64-round compression function
fn compress(
  state: #(Int, Int, Int, Int, Int, Int, Int, Int),
  words: List(Int),
) -> #(Int, Int, Int, Int, Int, Int, Int, Int) {
  let #(h0, h1, h2, h3, h4, h5, h6, h7) = state
  let #(a, b, c, d, e, f, g, h) =
    compress_rounds(#(h0, h1, h2, h3, h4, h5, h6, h7), words, 0)
  #(
    add32(h0, a),
    add32(h1, b),
    add32(h2, c),
    add32(h3, d),
    add32(h4, e),
    add32(h5, f),
    add32(h6, g),
    add32(h7, h),
  )
}

fn compress_rounds(
  state: #(Int, Int, Int, Int, Int, Int, Int, Int),
  words: List(Int),
  round: Int,
) -> #(Int, Int, Int, Int, Int, Int, Int, Int) {
  case words {
    [] -> state
    [word, ..rest] -> {
      let #(a, b, c, d, e, f, g, h) = state
      let temp1 =
        add32(
          add32(h, big_sigma1(e)),
          add32(choose(e, f, g), add32(round_constant(round), word)),
        )
      let temp2 = add32(big_sigma0(a), majority(a, b, c))
      compress_rounds(
        #(add32(temp1, temp2), a, b, c, add32(d, temp1), e, f, g),
        rest,
        round + 1,
      )
    }
  }
}

fn state_to_bytes(
  state: #(Int, Int, Int, Int, Int, Int, Int, Int),
) -> BitArray {
  let #(h0, h1, h2, h3, h4, h5, h6, h7) = state
  <<h0:32, h1:32, h2:32, h3:32, h4:32, h5:32, h6:32, h7:32>>
}
