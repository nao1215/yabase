import gleam/bit_array
import gleam/list
import yabase

// Independent Python hashlib + integer-radix vectors at SHA-256 block boundaries.

pub fn checksum_0_byte_payload_test() -> Nil {
  let payload = bit_array.concat(list.repeat(<<255>>, 0))
  assert yabase.encode(payload, using: yabase.Base58Check(128)) == Ok("FXjQL6s")
  let assert Ok(decoded) = yabase.decode_base58check("FXjQL6s")
  assert decoded.payload == payload
  assert decoded.version == 128
}

pub fn checksum_54_byte_payload_test() -> Nil {
  let payload = bit_array.concat(list.repeat(<<255>>, 54))
  assert yabase.encode(payload, using: yabase.Base58Check(128))
    == Ok(
      "6BQ3wZpsHdHkpYZdEopAmnPQzqM2Q5MrivHGP9mNkvWL6GHod23FEknfzsXUDXENhpkzvWszUi5YpPfo1",
    )
  let assert Ok(decoded) =
    yabase.decode_base58check(
      "6BQ3wZpsHdHkpYZdEopAmnPQzqM2Q5MrivHGP9mNkvWL6GHod23FEknfzsXUDXENhpkzvWszUi5YpPfo1",
    )
  assert decoded.payload == payload
  assert decoded.version == 128
}

pub fn checksum_55_byte_payload_test() -> Nil {
  let payload = bit_array.concat(list.repeat(<<255>>, 55))
  assert yabase.encode(payload, using: yabase.Base58Check(128))
    == Ok(
      "PrtjyqtGxPAxQrJzwwdC8fKvvGPPArF4U2Antmgs2sATGEVAmyauqiGb8S1V8GS2oBoCfCt4hJK6eN59sE",
    )
  let assert Ok(decoded) =
    yabase.decode_base58check(
      "PrtjyqtGxPAxQrJzwwdC8fKvvGPPArF4U2Antmgs2sATGEVAmyauqiGb8S1V8GS2oBoCfCt4hJK6eN59sE",
    )
  assert decoded.payload == payload
  assert decoded.version == 128
}

pub fn checksum_56_byte_payload_test() -> Nil {
  let payload = bit_array.concat(list.repeat(<<255>>, 56))
  assert yabase.encode(payload, using: yabase.Base58Check(128))
    == Ok(
      "2juDNhtmKRSrwaGeSmW6k8pAYz6unrUM4JGADZWEwqEQivEXL9WkgE19odoP9957UvrevTdSPJsQtKp6FYUA",
    )
  let assert Ok(decoded) =
    yabase.decode_base58check(
      "2juDNhtmKRSrwaGeSmW6k8pAYz6unrUM4JGADZWEwqEQivEXL9WkgE19odoP9957UvrevTdSPJsQtKp6FYUA",
    )
  assert decoded.payload == payload
  assert decoded.version == 128
}

pub fn checksum_62_byte_payload_test() -> Nil {
  let payload = bit_array.concat(list.repeat(<<255>>, 62))
  assert yabase.encode(payload, using: yabase.Base58Check(128))
    == Ok(
      "4pmpDhydiBtvMeWcMAuTe1V9Atk13p2xNZvRq2Jmg4Sy4C6aQDjPbewFjq2Zjkvd4h3Zzwk2xaXz2TLjZedgKbwCcxJ6",
    )
  let assert Ok(decoded) =
    yabase.decode_base58check(
      "4pmpDhydiBtvMeWcMAuTe1V9Atk13p2xNZvRq2Jmg4Sy4C6aQDjPbewFjq2Zjkvd4h3Zzwk2xaXz2TLjZedgKbwCcxJ6",
    )
  assert decoded.payload == payload
  assert decoded.version == 128
}

pub fn checksum_63_byte_payload_test() -> Nil {
  let payload = bit_array.concat(list.repeat(<<255>>, 63))
  assert yabase.encode(payload, using: yabase.Base58Check(128))
    == Ok(
      "HsroR5ry2o6AW8Zh22iYaM9D4fNoDQbdQCJpaxmSBQDcR5ycRVC6jxSU42yuVisgBHkLekcweK1khRG6s76tZ7gzY7Le9",
    )
  let assert Ok(decoded) =
    yabase.decode_base58check(
      "HsroR5ry2o6AW8Zh22iYaM9D4fNoDQbdQCJpaxmSBQDcR5ycRVC6jxSU42yuVisgBHkLekcweK1khRG6s76tZ7gzY7Le9",
    )
  assert decoded.payload == payload
  assert decoded.version == 128
}

pub fn checksum_64_byte_payload_test() -> Nil {
  let payload = bit_array.concat(list.repeat(<<255>>, 64))
  assert yabase.encode(payload, using: yabase.Base58Check(128))
    == Ok(
      "2HVUosJTYJvRnwaPHdYaNNBuEFAPCym9qfNuf2u988uUfKJxsM5RzLbhQQPkAhmpfvQvHjdXeBgWKsQ5et9vzYkXbXXhbE5",
    )
  let assert Ok(decoded) =
    yabase.decode_base58check(
      "2HVUosJTYJvRnwaPHdYaNNBuEFAPCym9qfNuf2u988uUfKJxsM5RzLbhQQPkAhmpfvQvHjdXeBgWKsQ5et9vzYkXbXXhbE5",
    )
  assert decoded.payload == payload
  assert decoded.version == 128
}

pub fn checksum_127_byte_payload_test() -> Nil {
  let payload = bit_array.concat(list.repeat(<<255>>, 127))
  assert yabase.encode(payload, using: yabase.Base58Check(128))
    == Ok(
      "2VP44yRG44zyAm4S59uNaYN5oNRRihDznGwSTyi19Q5Rk9Cz2toxruZJ9N1u6ueJKLsSQAK8EDtMaDfB6VzEijqgCtpomkBJV6Hz1ts8Chd483Qh7pM1qD8iuhZANy44XVyw9Wq7whpmrpgpiP2Szr1KgA9kSKvASeAnLVskg4njnsSwamtm2",
    )
  let assert Ok(decoded) =
    yabase.decode_base58check(
      "2VP44yRG44zyAm4S59uNaYN5oNRRihDznGwSTyi19Q5Rk9Cz2toxruZJ9N1u6ueJKLsSQAK8EDtMaDfB6VzEijqgCtpomkBJV6Hz1ts8Chd483Qh7pM1qD8iuhZANy44XVyw9Wq7whpmrpgpiP2Szr1KgA9kSKvASeAnLVskg4njnsSwamtm2",
    )
  assert decoded.payload == payload
  assert decoded.version == 128
}

pub fn checksum_128_byte_payload_test() -> Nil {
  let payload = bit_array.concat(list.repeat(<<255>>, 128))
  assert yabase.encode(payload, using: yabase.Base58Check(128))
    == Ok(
      "7aGLYY25SYerv5U9fLJAF3S4BfYp72YN2qMHQ5Hye4rYDRDtjMgHZGyYfukxy5MdRxhd7E6zuMsfocsVZGwdZE5r3Vk1SVaUAzMxewvEneJ8n5da55yLfnZ5ybzxPxQWZcvHzafPeTBrzuUmbeDPkKJRRqPcinVegB4B74T1mRissTfXcxyqFu",
    )
  let assert Ok(decoded) =
    yabase.decode_base58check(
      "7aGLYY25SYerv5U9fLJAF3S4BfYp72YN2qMHQ5Hye4rYDRDtjMgHZGyYfukxy5MdRxhd7E6zuMsfocsVZGwdZE5r3Vk1SVaUAzMxewvEneJ8n5da55yLfnZ5ybzxPxQWZcvHzafPeTBrzuUmbeDPkKJRRqPcinVegB4B74T1mRissTfXcxyqFu",
    )
  assert decoded.payload == payload
  assert decoded.version == 128
}
