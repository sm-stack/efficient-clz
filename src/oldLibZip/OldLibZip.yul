// LibZip.cdCompress(bytes) in Yul format
object "OldLibZip" {
  code {
    datacopy(0, dataoffset("Runtime"), datasize("Runtime"))
    return(0, datasize("Runtime"))
  }
  object "Runtime" {
    code {
      // selector: 0x83a09505 ("cdCompress(bytes)")
      if lt(calldatasize(), 4) { revert(0, 0) }
      calldatacopy(0, 0, 4)
      let sel := shr(224, mload(0))
      if iszero(eq(sel, 0x83a09505)) { revert(0,0) }

      // decode bytes from calldata
      calldatacopy(0, 4, 0x20)
      let off := mload(0)
      calldatacopy(0x20, add(4, off), 0x20)
      let len := mload(0x20)
      let dataPtr := add(add(4, off), 0x20)

      // Copy input bytes to memory
      let data := mload(0x40)
      calldatacopy(data, dataPtr, len)
      mstore(data, len)  // Store length at data[0]
      mstore(add(data, add(0x20, len)), 0)  // Zero tail
      mstore(0x40, add(data, add(0x40, len)))  // Bump free mem

      // LibZip.sol cdCompress assembly block
      function countLeadingZeroBytes(x_) -> _r {
          _r := shl(7, lt(0xffffffffffffffffffffffffffffffff, x_))
          _r := or(_r, shl(6, lt(0xffffffffffffffff, shr(_r, x_))))
          _r := or(_r, shl(5, lt(0xffffffff, shr(_r, x_))))
          _r := or(_r, shl(4, lt(0xffff, shr(_r, x_))))
          _r := xor(31, or(shr(3, _r), lt(0xff, shr(_r, x_))))
      }
      function min(x_, y_) -> _z {
          _z := xor(x_, mul(xor(x_, y_), lt(y_, x_)))
      }
      let result := mload(0x40)
      let end := add(data, mload(data))
      let m := 0x7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f
      let o := add(result, 0x20)
      for { let i := data } iszero(eq(i, end)) {} {
          i := add(i, 1)
          let c := byte(31, mload(i))
          if iszero(c) {
              for {} 1 {} {
                  let x := mload(add(i, 0x20))
                  if iszero(x) {
                      let r := min(sub(end, i), 0x20)
                      r := min(sub(0x7f, c), r)
                      i := add(i, r)
                      c := add(c, r)
                      if iszero(gt(r, 0x1f)) { break }
                      continue
                  }
                  let r := countLeadingZeroBytes(x)
                  r := min(sub(end, i), r)
                  i := add(i, r)
                  c := add(c, r)
                  break
              }
              mstore(o, shl(240, c))
              o := add(o, 2)
              continue
          }
          if eq(c, 0xff) {
              let r := 0x20
              let x := not(mload(add(i, r)))
              if x { r := countLeadingZeroBytes(x) }
              r := min(min(sub(end, i), r), 0x1f)
              i := add(i, r)
              mstore(o, shl(240, or(r, 0x80)))
              o := add(o, 2)
              continue
          }
          mstore8(o, c)
          o := add(o, 1)
          c := mload(add(i, 0x20))
          mstore(o, c)

          // `.each(b => b == 0x00 || b == 0xff ? 0x80 : 0x00)`.
          c := not(or(and(or(add(and(c, m), m), c), or(add(and(not(c), m), m), not(c))), m))
          let r := shl(7, lt(0x8421084210842108cc6318c6db6d54be, c)) // Save bytecode.
          r := or(shl(6, lt(0xffffffffffffffff, shr(r, c))), r)
          // forgefmt: disable-next-item
          r := add(iszero(c), shr(3, xor(byte(and(0x1f, shr(byte(24,
              mul(0x02040810204081, shr(r, c))), 0x8421084210842108cc6318c6db6d54be)),
              0xc0c8c8d0c8e8d0d8c8e8e0e8d0d8e0f0c8d0e8d0e0e0d8f0d0d0e0d8f8f8f8f8), r)))
          r := min(sub(end, i), r)
          o := add(o, r)
          i := add(i, r)
      }
      // Bitwise negate the first 4 bytes.
      mstore(add(result, 4), not(mload(add(result, 4))))
      mstore(result, sub(o, add(result, 0x20)))
      mstore(o, 0)
      mstore(0x40, add(o, 0x20))

      // Return raw bytes data only
      let resLen := mload(result)
      let dataStart := add(result, 0x20)
      return(dataStart, resLen)
    }
  }
}
