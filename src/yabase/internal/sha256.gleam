/// Pure Gleam SHA-256 implementation.
/// Used only for checksum computation in Base58Check.
import gleam/bit_array

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
fn k(i: Int) -> Int {
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

fn mask32(n: Int) -> Int {
  let m = 0xFFFFFFFF
  case n >= 0 {
    True -> int_and(n, m)
    False -> int_and(n + m + 1, m)
  }
}

fn int_and(a: Int, b: Int) -> Int {
  do_int_and(a, b, 0, 1)
}

fn do_int_and(a: Int, b: Int, result: Int, bit: Int) -> Int {
  case bit > 0xFFFFFFFF {
    True -> result
    False -> {
      let bit_set = case { a / bit } % 2 == 1 && { b / bit } % 2 == 1 {
        True -> bit
        False -> 0
      }
      do_int_and(a, b, result + bit_set, bit * 2)
    }
  }
}

fn int_or(a: Int, b: Int) -> Int {
  do_int_or(a, b, 0, 1)
}

fn do_int_or(a: Int, b: Int, result: Int, bit: Int) -> Int {
  case bit > 0xFFFFFFFF {
    True -> result
    False -> {
      let bit_set = case { a / bit } % 2 == 1 || { b / bit } % 2 == 1 {
        True -> bit
        False -> 0
      }
      do_int_or(a, b, result + bit_set, bit * 2)
    }
  }
}

fn int_xor(a: Int, b: Int) -> Int {
  do_int_xor(a, b, 0, 1)
}

fn do_int_xor(a: Int, b: Int, result: Int, bit: Int) -> Int {
  case bit > 0xFFFFFFFF {
    True -> result
    False -> {
      let a_bit = { a / bit } % 2
      let b_bit = { b / bit } % 2
      let bit_set = case a_bit != b_bit {
        True -> bit
        False -> 0
      }
      do_int_xor(a, b, result + bit_set, bit * 2)
    }
  }
}

fn int_not(a: Int) -> Int {
  int_xor(a, 0xFFFFFFFF)
}

fn shr(n: Int, amount: Int) -> Int {
  do_shr(mask32(n), amount)
}

fn do_shr(n: Int, amount: Int) -> Int {
  case amount {
    0 -> n
    _ -> do_shr(n / 2, amount - 1)
  }
}

fn rotr(n: Int, amount: Int) -> Int {
  let masked = mask32(n)
  int_or(shr(masked, amount), mask32(shl(masked, 32 - amount)))
}

fn shl(n: Int, amount: Int) -> Int {
  do_shl(n, amount)
}

fn do_shl(n: Int, amount: Int) -> Int {
  case amount {
    0 -> n
    _ -> do_shl(n * 2, amount - 1)
  }
}

fn add32(a: Int, b: Int) -> Int {
  mask32(a + b)
}

// SHA-256 functions
fn ch(x: Int, y: Int, z: Int) -> Int {
  int_xor(int_and(x, y), int_and(int_not(x), z))
}

fn maj(x: Int, y: Int, z: Int) -> Int {
  int_xor(int_xor(int_and(x, y), int_and(x, z)), int_and(y, z))
}

fn big_sigma0(x: Int) -> Int {
  int_xor(int_xor(rotr(x, 2), rotr(x, 13)), rotr(x, 22))
}

fn big_sigma1(x: Int) -> Int {
  int_xor(int_xor(rotr(x, 6), rotr(x, 11)), rotr(x, 25))
}

fn small_sigma0(x: Int) -> Int {
  int_xor(int_xor(rotr(x, 7), rotr(x, 18)), shr(x, 3))
}

fn small_sigma1(x: Int) -> Int {
  int_xor(int_xor(rotr(x, 17), rotr(x, 19)), shr(x, 10))
}

// Message padding: append 1 bit, pad zeros, append 64-bit big-endian length
fn pad_message(data: BitArray) -> BitArray {
  let bit_len = bit_array.byte_size(data) * 8
  let high = bit_len / 4_294_967_296
  let low = bit_len % 4_294_967_296
  // Append 0x80 byte
  let with_one = bit_array.append(data, <<0x80>>)
  // Pad to 56 mod 64 bytes
  let padded = pad_zeros(with_one)
  // Append full 64-bit big-endian length (FIPS 180-4 Section 5.1.1)
  bit_array.append(padded, <<high:32, low:32>>)
}

fn pad_zeros(data: BitArray) -> BitArray {
  case bit_array.byte_size(data) % 64 {
    56 -> data
    _ -> pad_zeros(bit_array.append(data, <<0>>))
  }
}

// Process 512-bit (64-byte) blocks
fn process_blocks(
  data: BitArray,
  state: #(Int, Int, Int, Int, Int, Int, Int, Int),
) -> #(Int, Int, Int, Int, Int, Int, Int, Int) {
  case data {
    <<block:bytes-size(64), rest:bits>> -> {
      let w = parse_block(block)
      let new_state = compress(state, w)
      process_blocks(rest, new_state)
    }
    _ -> state
  }
}

// Parse 64-byte block into 16 32-bit words, then expand to 64 words
fn parse_block(block: BitArray) -> List(Int) {
  let w16 = parse_words(block, [])
  expand_schedule(w16, 16)
}

fn parse_words(data: BitArray, acc: List(Int)) -> List(Int) {
  case data {
    <<w:32, rest:bits>> -> parse_words(rest, list_append(acc, [w]))
    _ -> acc
  }
}

fn expand_schedule(w: List(Int), i: Int) -> List(Int) {
  case i >= 64 {
    True -> w
    False -> {
      let w2 = list_at(w, i - 2)
      let w7 = list_at(w, i - 7)
      let w15 = list_at(w, i - 15)
      let w16 = list_at(w, i - 16)
      let new_w =
        add32(add32(small_sigma1(w2), w7), add32(small_sigma0(w15), w16))
      expand_schedule(list_append(w, [new_w]), i + 1)
    }
  }
}

// 64-round compression function
fn compress(
  state: #(Int, Int, Int, Int, Int, Int, Int, Int),
  w: List(Int),
) -> #(Int, Int, Int, Int, Int, Int, Int, Int) {
  let #(h0, h1, h2, h3, h4, h5, h6, h7) = state
  let #(a, b, c, d, e, f, g, h) =
    compress_rounds(#(h0, h1, h2, h3, h4, h5, h6, h7), w, 0)
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
  vars: #(Int, Int, Int, Int, Int, Int, Int, Int),
  w: List(Int),
  i: Int,
) -> #(Int, Int, Int, Int, Int, Int, Int, Int) {
  case i >= 64 {
    True -> vars
    False -> {
      let #(a, b, c, d, e, f, g, h) = vars
      let t1 =
        add32(
          add32(h, big_sigma1(e)),
          add32(ch(e, f, g), add32(k(i), list_at(w, i))),
        )
      let t2 = add32(big_sigma0(a), maj(a, b, c))
      compress_rounds(
        #(add32(t1, t2), a, b, c, add32(d, t1), e, f, g),
        w,
        i + 1,
      )
    }
  }
}

fn state_to_bytes(state: #(Int, Int, Int, Int, Int, Int, Int, Int)) -> BitArray {
  let #(h0, h1, h2, h3, h4, h5, h6, h7) = state
  <<h0:32, h1:32, h2:32, h3:32, h4:32, h5:32, h6:32, h7:32>>
}

fn list_at(l: List(Int), index: Int) -> Int {
  case l, index {
    [h, ..], 0 -> h
    [_, ..rest], n -> list_at(rest, n - 1)
    [], _ -> 0
  }
}

fn list_append(l: List(a), items: List(a)) -> List(a) {
  case l {
    [] -> items
    [h, ..t] -> [h, ..list_append(t, items)]
  }
}
