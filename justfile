rpc_url := "https://sepolia.drpc.org"

build:
    @echo "Building Yul contracts..."
    FOUNDRY_PROFILE=oldlibzip forge build --offline src/oldLibZip/OldLibZip.yul 2>&1 | grep -v "expected identifier" || true
    FOUNDRY_PROFILE=newlibzip forge build --offline src/newLibZip/NewLibZip.yul 2>&1 | grep -v "expected identifier" || true
    FOUNDRY_PROFILE=oldfloorsqrt forge build --offline src/oldFloorSqrt/OldFloorSqrt.yul 2>&1 | grep -v "expected identifier" || true
    FOUNDRY_PROFILE=newfloorsqrt forge build --offline src/newFloorSqrt/NewFloorSqrt.yul 2>&1 | grep -v "expected identifier" || true
    @echo "Building Solidity contracts..."
    forge build --via-ir

test:
    forge test --rpc-url {{ rpc_url }} -vvv

snapshot:
    @echo "📸 Taking gas snapshots..."
    @mkdir -p snapshots
    @echo "Snapshot for LibZip tests..."
    forge snapshot --match-path "test/LibZip.t.sol" --snap snapshots/libzip.gas
    @echo "Snapshot for Sqrt tests..."
    forge snapshot --match-path "test/Sqrt.t.sol" --snap snapshots/sqrt.gas
    @echo "✅ Snapshots saved:"
    @echo "  - snapshots/libzip.gas"
    @echo "  - snapshots/sqrt.gas"

# Deploy contracts to Sepolia and run gas tests
deploy:
    @echo "🚀 Deploying contracts to Sepolia..."
    @if [ -z "$$PRIVATE_KEY" ]; then \
        echo "❌ Error: PRIVATE_KEY environment variable is not set"; \
        echo "Usage: PRIVATE_KEY=0x... just deploy"; \
        exit 1; \
    fi
    @bash script/deploy.sh

# Run gas comparison tests on deployed contracts
# Usage: just test-gas <old_address> <new_address>
test-gas old_addr new_addr:
    @echo "📊 Running gas comparison tests..."
    @bash script/test_gas.sh {{ old_addr }} {{ new_addr }}

# Deploy and test (convenience command)
deploy-and-test:
    #!/usr/bin/env bash
    set -euo pipefail
    if [ -z "${PRIVATE_KEY:-}" ]; then
        echo "❌ Error: PRIVATE_KEY environment variable is not set"
        echo "Usage: PRIVATE_KEY=0x... just deploy-and-test"
        exit 1
    fi
    echo "🚀 Deploying and testing..."
    bash script/deploy.sh | tee /tmp/deploy_output.txt
    OLD_ADDR=$(grep "OldLibZip deployed at:" /tmp/deploy_output.txt | awk '{print $NF}')
    NEW_ADDR=$(grep "NewLibZip deployed at:" /tmp/deploy_output.txt | awk '{print $NF}')
    if [ -n "$OLD_ADDR" ] && [ -n "$NEW_ADDR" ]; then
        echo ""
        echo "=========================================="
        echo "📊 Running comprehensive gas tests..."
        echo "=========================================="
        echo ""
        bash script/test_gas.sh $OLD_ADDR $NEW_ADDR
    else
        echo "❌ Failed to extract deployed addresses"
        exit 1
    fi