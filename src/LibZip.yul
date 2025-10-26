object "YulLibZip" {
  code {
    // constructor: return runtime code
    datacopy(0, dataoffset("Runtime"), datasize("Runtime"))
    return(0, datasize("Runtime"))
  }
  object "Runtime" {
    code {
      // Minimal function selector dispatch for: cdCompress(bytes)
      // selector: 0x83a09505 = keccak256("cdCompress(bytes)")[:4]
      // layout: calldata: [4-byte selector][bytes offset=0x20][bytes length][bytes data]
      if iszero(calldatasize()) { return(0, 0) }

      // Load selector
      calldatacopy(0, 0, 4)
      let sel := shr(224, mload(0))

      // Check selector: 0x83a09505
      if eq(sel, 0x83a09505) {
        // Decode bytes argument
        // ABI: at calldata 4, the first word is offset (expect 0x20)
        // Then at calldata 4+off, we have the length, then the data
        calldatacopy(0, 4, 0x20)
        let off := mload(0)
        // Load length from calldata at position 4 + off
        calldatacopy(0x20, add(4, off), 0x20)
        let len := mload(0x20)
        // Pointer to bytes data in calldata (skip 4-byte selector + off + 0x20 for length)
        let dataPtr := add(add(4, off), 0x20)

        // Allocate result memory (start fresh to avoid clobbering)
        let result := 0x80
        // Reserve head
        mstore(result, 0) // length placeholder
        let out := add(result, 0x20)

        // Compression: we implement the same logic as Solidity's NewLibZip.cdCompress
        // Ported the calldata-selective RLE used in LibZip (0x00 and 0xff runs + passthrough blocks).
        // Note: We'll operate on memory copy of input for simplicity.
        let inMem := add(result, 0x40)
        // Copy input into memory after the output head to keep one contiguous region
        {
          // allocate input space rounded to 32 bytes
          let copyWords := and(add(add(len, 0x1f), not(0x1f)), not(0x1f))
          calldatacopy(inMem, dataPtr, len)
          // zero tail
          mstore(add(inMem, len), 0)
          // Processing variables
          let end := add(inMem, len)
          let m := 0x7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f
          let o := out
          for { let i := sub(inMem, 1) } iszero(eq(i, sub(end, 1))) {} {
            i := add(i, 1)
            let c := byte(0, mload(i))
            if iszero(c) {
              // count 0x00 run length, up to 0x7f
              let run := 0
              for { } 1 { } {
                let x := mload(add(i, 1))
                if iszero(x) {
                  let r := sub(end, i)
                  r := xor(r, mul(gt(r, 0x20), xor(r, 0x20)))
                  r := xor(r, mul(gt(add(run, r), 0x7f), xor(r, sub(0x7f, run))))
                  i := add(i, r)
                  run := add(run, r)
                  if iszero(gt(r, 0x1f)) { break }
                  continue
                }
                // count leading zero bytes in x
                // portable CLZ-bytes
                let r := 0
                {
                  let t := shl(7, lt(0xffffffffffffffffffffffffffffffff, x))
                  t := or(t, shl(6, lt(0xffffffffffffffff, shr(t, x))))
                  t := or(t, shl(5, lt(0xffffffff, shr(t, x))))
                  t := or(t, shl(4, lt(0xffff, shr(t, x))))
                  r := xor(31, or(shr(3, t), lt(0xff, shr(t, x))))
                }
                r := xor(r, mul(gt(r, sub(end, i)), xor(r, sub(end, i))))
                i := add(i, r)
                run := add(run, r)
                break
              }
              mstore(o, shl(240, run))
              o := add(o, 2)
              continue
            }
            if eq(c, 0xff) {
              let r := 0x20
              let x := not(mload(add(i, r)))
              if x {
                // count leading zero bytes in x
                let t := shl(7, lt(0xffffffffffffffffffffffffffffffff, x))
                t := or(t, shl(6, lt(0xffffffffffffffff, shr(t, x))))
                t := or(t, shl(5, lt(0xffffffff, shr(t, x))))
                t := or(t, shl(4, lt(0xffff, shr(t, x))))
                r := xor(31, or(shr(3, t), lt(0xff, shr(t, x))))
              }
              // clamp r
              {
                let rem := sub(end, i)
                r := xor(r, mul(gt(r, rem), xor(r, rem)))
                r := xor(r, mul(gt(r, 0x1f), xor(r, 0x1f)))
              }
              i := add(i, r)
              mstore(o, shl(240, or(r, 0x80)))
              o := add(o, 2)
              continue
            }
            // passthrough block
            mstore8(o, c)
            o := add(o, 1)
            let w := mload(add(i, 1))
            mstore(o, w)
            // mark non-00/ff bytes
            let mask := 0x7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f
            w := not(or(and(or(add(and(w, mask), mask), w), or(add(and(not(w), mask), mask), not(w))), mask))
            let r2 := shl(7, lt(0x8421084210842108cc6318c6db6d54be, w))
            r2 := or(shl(6, lt(0xffffffffffffffff, shr(r2, w))), r2)
            r2 := add(iszero(w), shr(3, xor(byte(and(0x1f, shr(byte(24, mul(0x02040810204081, shr(r2, w))), 0x8421084210842108cc6318c6db6d54be)), 0xc0c8c8d0c8e8d0d8c8e8e0e8d0d8e0f0c8d0e8d0e0e0d8f0d0d0e0d8f8f8f8f8), r2)))
            r2 := xor(r2, mul(gt(r2, sub(end, i)), xor(r2, sub(end, i))))
            o := add(o, r2)
            i := add(i, r2)
          }
          // finalize: negate first 4 bytes of output
          mstore(add(out, 4), not(mload(add(out, 4))))
          let compressedLen := sub(o, out)
          
          // ABI encode return: [offset=0x20][length][data...]
          mstore(0x80, 0x20)  // offset to bytes
          mstore(0xa0, compressedLen)  // bytes length
          // Copy compressed data to 0xc0
          let src := out
          let dst := 0xc0
          for { let i := 0 } lt(i, compressedLen) { i := add(i, 0x20) } {
            mstore(add(dst, i), mload(add(src, i)))
          }
          // Return ABI-encoded bytes
          return(0x80, add(0x40, compressedLen))
        }
      }
      // default
      revert(0, 0)
    }
  }
}
