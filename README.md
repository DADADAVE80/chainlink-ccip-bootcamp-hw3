# Chainlink CCIP Bootcamp Homework 3 Submission

## Prerequisites

- [Foundry](https://book.getfoundry.sh/getting-started/installation)

## Getting Started

1. Install packages

```
forge install
```

and

```
npm install
```

2. Compile contracts

```
forge build
```

## Usage

Create an account profile with your private key if you haven't already.

```shell
cast wallet import <REPLACE_WITH_ACCOUNT_NAME> --interactive
```

Create a new file by copying the `.env.example` file, and name it `.env`. Fill in your RPC URLs

```shell
ETHEREUM_SEPOLIA_RPC_URL=""
AVALANCHE_FUJI_RPC_URL=""
```

Once that is done, to load the variables in the `.env` file, run the following command:

```shell
source .env
```

### Faucet

- Chainlink Faucet: https://faucets.chain.link
- Circle USDC Faucet: https://faucet.circle.com

### Step 1 - Transfer USDC from Fuji to Sepolia (EOA to EOA)

To transfer USDC from Avalanche Fuji to Ethereum Sepolia you can use the `script/EstimateCCIPReceiveGas.s.sol:TransferUsdcFromFujiToSep` smart contract:

```shell
forge script script/EstimateCCIPReceiveGas.s.sol:TransferUsdcFromFujiToSep \
--rpc-url $ETHEREUM_SEPOLIA_RPC_URL\
--account <ACCOUNT_NAME> \
--broadcast \
--sender <PUBLIC_ADDRESS>
```

### Step 2 - Deploy SwapTestnetUSDC and CrossChainReceiver Smart Contract on Sepolia

To deploy SwapTestnetUSDC and CrossChainReceiver smart contracts on Ethereum Sepolia you can use the `script/EstimateCCIPReceiveGas.s.sol:TransferUsdcFromFujiToSep` smart contract:

```shell
forge script script/EstimateCCIPReceiveGas.s.sol:DeploySwapTestnetUSDCandCrossChainReceiverOnSep \
-s "run(address)" <TRANSFER_USDC_ADDRESS> \
--rpc-url $ETHEREUM_SEPOLIA_RPC_URL\
--account <ACCOUNT_NAME> \
--broadcast \
--sender <PUBLIC_ADDRESS>
```

### Step 3 - Transfer USDC from Avalanche Fuji to CrossChainReceiver smart contract on Ethereum Sepolia

```shell
forge script script/EstimateCCIPReceiveGas.s.sol:TransferUsdcFromFujiToCompOnSep \
-s "run(address,address)" <TRANSFER_USDC_ADDRESS> <CROSS_CHAIN_RECEIVER_ADDRESS> \
--rpc-url $AVALANCHE_FUJI_RPC_URL \
--account <ACCOUNT_NAME> \
--broadcast \
--sender <PUBLIC_ADDRESS>
```

## `ccipReceive` gas consumption
5190 + 10% = 5709