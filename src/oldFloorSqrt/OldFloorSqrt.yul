object "OldFloorSqrt" {
    code {
        datacopy(0, dataoffset("Runtime"), datasize("Runtime"))
        return(0, datasize("Runtime"))
    }
    object "Runtime" {
        code {
            // ---- Check selector and load input ----
            if iszero(calldatasize()) { revert(0, 0) }
            
            // Check for function selector: floorSqrt(uint256) = 0x0cce06b6
            let selector := shr(224, calldataload(0))
            if iszero(eq(selector, 0x0cce06b6)) {
                revert(0, 0)
            }
            
            // Load n from calldata at offset 4 (after selector)
            let n := calldataload(4)

            // ---- floorSqrt(n) ----
            // if (n > 63) do Newton with initial y = 1 << (floorLog2(n)/2 + 1)
            // else lookup-table nibble
            function floorLog2(n_) -> r {
                // uint8 res = 0;
                // if (n < 256) { while(n>1){ n>>=1; res+=1; } }
                // else { for (s=128; s>0; s>>=1) if (n >= 1<<s){ n>>=s; res|=s; } }
                if lt(n_, 256) {
                    for { } gt(n_, 1) { n_ := shr(1, n_) } {
                        r := add(r, 1)
                    }
                } 
                if iszero(lt(n_, 256)) {
                    // s = 128; s > 0; s >>= 1
                    let s := 128
                    for { } gt(s, 0) { s := shr(1, s) } {
                        if iszero(lt(n_, shl(s, 1))) {
                            n_ := shr(s, n_)
                            r := or(r, s)
                        }
                    }
                }
                // r is uint8 in Solidity; returning 0..255 range as 256-bit is fine
            }

            let res := 0

            if gt(n, 63) {
                // x = n; y = 1 << (floorLog2(n)/2 + 1)
                let x := n
                let fl := floorLog2(n)
                let y := shl(add(shr(1, fl), 1), 1) // 1 << (fl/2 + 1)

                // while (x > y) { x = y; y = (x + n/x) >> 1; }
                // Use a bounded loop style while preserving logic
                for { } gt(x, y) { } {
                    x := y
                    y := shr(1, add(x, div(n, x)))
                }
                res := x
            }
            if iszero(gt(n, 63)) {
                // return (CONST >> (n*4)) & 0xf
                // 0x777...1110 constant exactly as in the Solidity snippet
                let C := 0x7777777777777776666666666666555555555554444444443333333222221110
                res := and(shr(mul(n, 4), C), 0xf)
            }

            mstore(0, res)
            return(0, 32)
        }
    }
}