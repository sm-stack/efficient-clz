#!/bin/bash

# Test deployed LibZip contracts with various data
# Usage: ./test_gas.sh <old_address> <new_address>

set -e

RPC_URL="https://sepolia.drpc.org"

if [ -z "$1" ] || [ -z "$2" ]; then
    echo "Usage: ./test_gas.sh <old_libzip_address> <new_libzip_address>"
    exit 1
fi

OLD_ADDR=$1
NEW_ADDR=$2

echo "📊 Testing LibZip Gas Consumption"
echo "================================"
echo "OldLibZip: $OLD_ADDR"
echo "NewLibZip: $NEW_ADDR"
echo ""

function test_case() {
    local name=$1
    local data=$2
    
    echo "🧪 Test: $name"
    echo "Data: $data"
    
    # Prepare calldata: cdCompress(bytes)
    local calldata="0x83a09505$(cast abi-encode "f(bytes)" "$data" | sed 's/0x//')"
    
    # Test OldLibZip
    local old_gas=$(cast estimate --rpc-url $RPC_URL $OLD_ADDR "$calldata" 2>/dev/null || echo "FAILED")
    echo "  OldLibZip: $old_gas gas"
    
    # Test NewLibZip
    local new_gas=$(cast estimate --rpc-url $RPC_URL $NEW_ADDR "$calldata" 2>/dev/null || echo "FAILED")
    echo "  NewLibZip: $new_gas gas"
    
    if [ "$old_gas" != "FAILED" ] && [ "$new_gas" != "FAILED" ]; then
        local diff=$((new_gas - old_gas))
        if [ $diff -lt 0 ]; then
            echo "  ✅ Saved: $((-diff)) gas"
        else
            echo "  ⚠️  Extra: $diff gas"
        fi
    fi
    echo ""
}

# Test Case 1: Vectorized example (0x112233, 0x0102030405060708, 0xf1f2f3)
DATA1=$(cast abi-encode "f(uint256,uint256,uint256)" 0x112233 0x0102030405060708 0xf1f2f3)
test_case "Vectorized example (mixed sizes)" "$DATA1"

# Test Case 2: Heavy CLZ - 10 small numbers (1-10)
# Each has 31 leading zero bytes, triggers CLZ ~10 times
DATA2=$(cast abi-encode "f(uint256,uint256,uint256,uint256,uint256,uint256,uint256,uint256,uint256,uint256)" 1 2 3 4 5 6 7 8 9 10)
test_case "Heavy CLZ (1-10, 31 zeros each) 🔥" "$DATA2"

# Test Case 3: Mixed 0xff pattern - 12x 0xff values
# Creates both 0x00 runs and 0xff detection, maximizing CLZ usage
DATA3=$(cast abi-encode "f(uint256,uint256,uint256,uint256,uint256,uint256,uint256,uint256,uint256,uint256,uint256,uint256)" 0xff 0xff 0xff 0xff 0xff 0xff 0xff 0xff 0xff 0xff 0xff 0xff)
test_case "Mixed 0xff pattern (12x 0xff) 🔥🔥" "$DATA3"

echo "================================"
echo "✅ All tests completed"

