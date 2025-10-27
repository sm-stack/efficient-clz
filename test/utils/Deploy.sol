// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library Deploy {
    function deployCode(bytes memory runtime) public returns (address) {
        address deployed;
        assembly {
            let runtimeSize := mload(runtime)
            let ptr := mload(0x40)
            
            // Build wrapper manually byte by byte for clarity
            // Format: 61 LLLL 80 60 0a 3d 39 3d f3
            // where LLLL is 2-byte big-endian length
            
            // Byte 0: 0x61 (PUSH2)
            mstore8(ptr, 0x61)
            // Bytes 1-2: size as big-endian uint16
            mstore8(add(ptr, 1), shr(8, runtimeSize))
            mstore8(add(ptr, 2), and(runtimeSize, 0xff))
            // Byte 3: 0x80 (DUP1)
            mstore8(add(ptr, 3), 0x80)
            // Byte 4: 0x60 (PUSH1)
            mstore8(add(ptr, 4), 0x60)
            // Byte 5: 0x0a (10)
            mstore8(add(ptr, 5), 0x0a)
            // Byte 6: 0x3d (RETURNDATASIZE)
            mstore8(add(ptr, 6), 0x3d)
            // Byte 7: 0x39 (CODECOPY)
            mstore8(add(ptr, 7), 0x39)
            // Byte 8: 0x3d (RETURNDATASIZE)
            mstore8(add(ptr, 8), 0x3d)
            // Byte 9: 0xf3 (RETURN)
            mstore8(add(ptr, 9), 0xf3)
            
            // Copy runtime after wrapper (offset 0x0a = 10 bytes)
            let runtimePtr := add(runtime, 0x20)
            for { let i := 0 } lt(i, runtimeSize) { i := add(i, 0x20) } {
                mstore(add(add(ptr, 0x0a), i), mload(add(runtimePtr, i)))
            }
            
            // Deploy: CREATE with value=0, offset=ptr, size=0x0a+runtimeSize
            deployed := create(0, ptr, add(0x0a, runtimeSize))
            if iszero(deployed) {
                revert(0, 0)
            }
        }
        return deployed;
    }
}