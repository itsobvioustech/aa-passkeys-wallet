## An AA wallet implemented completely with PassKeys
A strawman implementation of an Ethereum wallet using PassKeys. This is a proof of concept, and is not intended to be used in production.
This is based off the [Infinitism Repo](https://github.com/eth-infinitism/account-abstraction) using [Foundry](https://github.com/foundry-rs/foundry) for build and test.

### Whats different on this implementation
1. A heavily modified and optimised version of the Secp256r1 signature verification solidity implementation contract which is used for verifying the signatures of the transactions.
2. Support for multiple Passkeys on an account.
3. Ability to remove a Passkey from an account.
4. A signature payload which heavily relies on the client to do as much of the prework as posible, this is to reduce the gas cost of the transactions.

### Setup
1. `forge install` to install the dependencies
2. `forge test` to run the tests
3. `forge build` to build the project
4. `forge build --skip test --skip script` to build the project for release
5. `npm run typechain` to generate the typechain files
6. `npm run build` to build the front end bindings

### Deploying locally
1. Bring up anvil with `anvil`
2. Install the Create2 proxy from [here](https://github.com/Arachnid/deterministic-deployment-proxy.git)
    1. TLDR
    2. Fund the deployer `0x3fab184622dc19b6109349b94811493bf2a45362` on testnet 
    3. Run `curl http://localhost:8545 -X 'POST' -H 'Content-Type: application/json' --data "{\"jsonrpc\":\"2.0\", \"id\":1, \"method\": \"eth_sendRawTransaction\", \"params\": [\"0xf8a58085174876e800830186a08080b853604580600e600039806000f350fe7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffe03601600081602082378035828234f58015156039578182fd5b8082525050506014600cf31ba02222222222222222222222222222222222222222222222222222222222222222a02222222222222222222222222222222222222222222222222222222222222222\"]}"`
3. Install the contracts `forge script script/PassKeysAccount.s.sol:AnvilScript --fork-url http://localhost:8545 --broadcast` uses `ANVIL_PRIVATE_KEY` env variable for deploying the contracts, ensure the account has enough funds to deploy the contracts.
