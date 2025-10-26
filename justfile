rpc_url := "https://sepolia.drpc.org/"

test:
    forge test --rpc-url {{ rpc_url }} -vvv

snapshot:
    forge snapshot --rpc-url {{ rpc_url }} --snap snapshots/libzip.gas