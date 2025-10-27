
object "NewFloorSqrt" {
    code {
        datacopy(0, dataoffset("Runtime"), datasize("Runtime"))
        return(0, datasize("Runtime"))
    }
    object "Runtime" {
        code {
            // Check selector and load input
            if iszero(calldatasize()) { revert(0, 0) }
            
            // Check for function selector: floorSqrt(uint256) = 0x0cce06b6
            let selector := shr(224, calldataload(0))
            if iszero(eq(selector, 0x0cce06b6)) {
                revert(0, 0)
            }
            
            // Load n from calldata at offset 4 (after selector)
            let n := calldataload(4)

            // floorLog2 via CLZ
            function floorLog2_CLZ(a) -> r {
                if iszero(a) { 
                    r := 0 
                }
                if a {
                    r := sub(255, verbatim_1i_1o(hex"1e", a))
                }
            }

            let res := 0

            if gt(n, 63) {
                // x = n; y = 1 << (floorLog2(n)/2 + 1)
                let x := n
                let fl := floorLog2_CLZ(n)
                
                if gt(fl, 255) { 
                    // CLZ returned invalid value, revert
                    revert(0, 0) 
                }
                
                let y := shl(add(shr(1, fl), 1), 1) // 1 << (fl/2 + 1)

                // while (x > y) { x = y; y = (x + n/x) >> 1; }
                let iter := 0
                for { } and(gt(x, y), lt(iter, 256)) { iter := add(iter, 1) } {
                    x := y
                    y := shr(1, add(x, div(n, x)))
                }
                res := x
            }
            if iszero(gt(n, 63)) {
                // same nibble table for small n (0..63)
                let C := 0x7777777777777776666666666666555555555554444444443333333222221110
                res := and(shr(mul(n, 4), C), 0xf)
            }

            mstore(0, res)
            return(0, 32)
        }
    }
}