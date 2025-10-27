#!/bin/bash

# Deploy LibZip contracts to testnet and measure gas
# Usage: 
#   1. Set PRIVATE_KEY environment variable
#   2. Run: ./deploy.sh

set -e

RPC_URL="https://sepolia.drpc.org"

if [ -z "$PRIVATE_KEY" ]; then
    echo "❌ PRIVATE_KEY not set"
    echo "Usage: PRIVATE_KEY=0x... ./deploy.sh"
    exit 1
fi

echo "🚀 Deploying LibZip contracts to Sepolia..."
echo ""

# Read bytecode from compiled output
OLD_RUNTIME=$(cat out/OldLibZip.yul/OldLibZip.json | jq -r '.deployedBytecode.object')
NEW_RUNTIME=$(cat out/NewLibZip.yul/NewLibZip.json | jq -r '.deployedBytecode.object')

# Create deployment bytecode with wrapper (from Deploy.sol logic)
# Wrapper format: 61<len> 80 600a 3d39 3d f3 <runtime>
function wrap_bytecode() {
    local runtime=$1
    local runtime_len=$((${#runtime}/2 - 1))  # Remove 0x and divide by 2
    local len_hex=$(printf "%04x" $runtime_len)
    echo "0x61${len_hex}80600a3d393df3${runtime:2}"
}

OLD_DEPLOY=$(wrap_bytecode "$OLD_RUNTIME")
NEW_DEPLOY=$(wrap_bytecode "$NEW_RUNTIME")

echo "📦 OldLibZip bytecode length: $((${#OLD_RUNTIME}/2 - 1)) bytes"
echo "📦 NewLibZip bytecode length: $((${#NEW_RUNTIME}/2 - 1)) bytes"
echo ""

# Deploy OldLibZip
echo "Deploying OldLibZip..."
OLD_ADDR=$(cast send --private-key $PRIVATE_KEY --rpc-url $RPC_URL --create $OLD_DEPLOY --json | jq -r '.contractAddress')
echo "✅ OldLibZip deployed at: $OLD_ADDR"

# Deploy NewLibZip
echo "Deploying NewLibZip..."
NEW_ADDR=$(cast send --private-key $PRIVATE_KEY --rpc-url $RPC_URL --create $NEW_DEPLOY --json | jq -r '.contractAddress')
echo "✅ NewLibZip deployed at: $NEW_ADDR"

echo ""
echo "📝 Deployed addresses:"
echo "  OldLibZip: $OLD_ADDR"
echo "  NewLibZip: $NEW_ADDR"
echo ""

# Prepare test data: abi.encode(1, 2, 3)
TEST_DATA="0x83a09505$(cast abi-encode "f(bytes)" "$(cast abi-encode "f(uint256,uint256,uint256)" 1 2 3)" | sed 's/0x//')"

echo "🧪 Testing compression..."
echo ""

# Test OldLibZip
echo "Calling OldLibZip.cdCompress()..."
OLD_RESULT=$(cast call --rpc-url $RPC_URL $OLD_ADDR $TEST_DATA)
echo "Result: $OLD_RESULT"

# Estimate gas for OldLibZip
OLD_GAS=$(cast estimate --rpc-url $RPC_URL $OLD_ADDR $TEST_DATA)
echo "🔥 OldLibZip gas: $OLD_GAS"
echo ""

# Test NewLibZip
echo "Calling NewLibZip.cdCompress()..."
NEW_RESULT=$(cast call --rpc-url $RPC_URL $NEW_ADDR $TEST_DATA)
echo "Result: $NEW_RESULT"

# Estimate gas for NewLibZip
NEW_GAS=$(cast estimate --rpc-url $RPC_URL $NEW_ADDR $TEST_DATA)
echo "🔥 NewLibZip gas: $NEW_GAS"
echo ""

# Compare
DIFF=$((NEW_GAS - OLD_GAS))
if [ $DIFF -lt 0 ]; then
    echo "✅ NewLibZip is cheaper by $((-DIFF)) gas!"
else
    echo "⚠️  NewLibZip uses $DIFF more gas"
fi

echo ""
echo "📊 Summary:"
echo "  OldLibZip: $OLD_GAS gas (portable CLZ)"
echo "  NewLibZip: $NEW_GAS gas (verbatim 0x1e CLZ)"
echo "  Difference: $DIFF gas"

