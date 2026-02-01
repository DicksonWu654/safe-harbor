# Safe Harbor V3 Deployment Guide

## Deployer Address Requirement

**ALL 4 transactions require deployment from this address:**
```
0xD9b8653Ab0bBa82C397b350F7319bA0c76d9F26a
```

This is because all transactions use **guarded CREATE3 salts**. The salt encodes the deployer address in the first 20 bytes, and CreateX will only allow deployment from that address.

### Why?
The calldata structure is: `deployCreate3(bytes32 salt, bytes initCode)`
- Salt format: `{deployer_address (20 bytes)}{0x00 (1 byte)}{salt_id (11 bytes)}`
- Example: `0xd9b8653ab0bba82c397b350f7319ba0c76d9f26a00...`

This ensures deterministic addresses AND prevents front-running by other deployers.

---

## Expected Deployed Addresses (All Chains)

| Contract | Expected Address |
|----------|------------------|
| ChainValidator (impl) | `0x1eee8E721816CD5A0033FBA6Ba93486C074dD1cB` |
| ChainValidator (proxy) | `0xd01C76ccE414d9B0a294abAFD94feD2e0B88675D` |
| SafeHarborRegistry | `0x326733493E143b8904716E7A64A9f4fb6A185a2c` |
| AgreementFactory | `0xcf317fE605397bC3fae6DAD06331aE5154F277fF` |

These addresses are deterministic via CREATE3 and will be the same on all chains.

---

## Calldata Files Overview

The calldata is **chain-dependent** due to the SafeHarborRegistry constructor parameters (`legacyRegistry` address and `adopters` array).

### Universal Calldata (0 Adopters)

For chains with **no existing V2 adopter migrations**, use the `universal-*` files:

| Chain | Files to Use |
|-------|-------------|
| Base | `universal-tx1/2/3/4` |
| Optimism | `universal-tx1/2/3/4` |
| Arbitrum | `universal-tx1/2/3/4` |
| Avalanche | `universal-tx1/2/3/4` |
| *Any new chain with 0 adopters* | `universal-tx1/2/3/4` |

### Chain-Specific Calldata (Has Adopters)

For chains with **existing V2 adopter migrations**, use chain-specific files:

| Chain | Files to Use | Adopters |
|-------|-------------|----------|
| Ethereum Mainnet | `mainnet-tx1/2/3/4` | 13 |
| Polygon | `polygon-tx1/2/3/4` | 3 (Ensuro, Polymarket, QuickSwap) |
| BNB | `bnb-tx1/2/3/4` | 1 (PancakeSwap) |

### Transaction Details

| TX # | Contract | Description | Calldata File | Chain-Dependent? |
|------|----------|-------------|---------------|------------------|
| 1 | **ChainValidator** (impl) | Implementation contract | `tx1-chainvalidator-impl.txt` | ❌ No |
| 2 | **ERC1967Proxy** (proxy) | Upgradeable proxy | `tx2-chainvalidator-proxy.txt` | ❌ No |
| 3 | **SafeHarborRegistry** | Main registry | `tx3-safeharborregistry.txt` | ✅ Yes |
| 4 | **AgreementFactory** | Factory contract | `tx4-agreementfactory.txt` | ❌ No |

**All transactions go to CreateX:** `0xba5Ed099633D3B313e4D5F7bdc1305d3c28ba5Ed`

---

## How to Generate Calldata for a New Chain

### Step 1: Check if the chain has existing V2 adopters

Open `script/HelperConfig.s.sol` and check the `get<Chain>Config()` function:

- If `adopters` array is **empty** → Use `universal-*` files
- If `adopters` array has **entries** → Generate chain-specific calldata

### Step 2: Generate calldata (if needed)

```bash
cd registry-contracts

# Simulate deployment for your chain
forge script script/Deploy.s.sol:DeploySafeHarbor \
  --rpc-url <YOUR_CHAIN_RPC_URL> \
  --sender 0xD9b8653Ab0bBa82C397b350F7319bA0c76d9F26a \
  -vvv
```

### Step 3: Extract calldata

```bash
# Create calldata directory
mkdir -p calldata

# Extract each transaction's calldata
CHAIN_ID=<your_chain_id>
cat broadcast/Deploy.s.sol/${CHAIN_ID}/dry-run/run-latest.json | jq -r '.transactions[0].transaction.input' > calldata/<chain>-tx1-chainvalidator-impl.txt
cat broadcast/Deploy.s.sol/${CHAIN_ID}/dry-run/run-latest.json | jq -r '.transactions[1].transaction.input' > calldata/<chain>-tx2-chainvalidator-proxy.txt
cat broadcast/Deploy.s.sol/${CHAIN_ID}/dry-run/run-latest.json | jq -r '.transactions[2].transaction.input' > calldata/<chain>-tx3-safeharborregistry.txt
cat broadcast/Deploy.s.sol/${CHAIN_ID}/dry-run/run-latest.json | jq -r '.transactions[3].transaction.input' > calldata/<chain>-tx4-agreementfactory.txt
```

### Step 4: Validate the calldata

Compare TX1, TX2, TX4 with universal files (should be identical):

```bash
# TX1 should match
diff calldata/universal-tx1-chainvalidator-impl.txt calldata/<chain>-tx1-chainvalidator-impl.txt

# TX2 should match
diff calldata/universal-tx2-chainvalidator-proxy.txt calldata/<chain>-tx2-chainvalidator-proxy.txt

# TX4 should match
diff calldata/universal-tx4-agreementfactory.txt calldata/<chain>-tx4-agreementfactory.txt

# TX3 will differ (contains chain-specific adopters)
```

---

## How to Regenerate All Calldata (Reference)

### Step 1: Run the deployment simulation

```bash
cd registry-contracts

# Simulate deployment (dry run)
forge script script/Deploy.s.sol:DeploySafeHarbor \
  --rpc-url https://ethereum-rpc.publicnode.com \
  --sender 0xD9b8653Ab0bBa82C397b350F7319bA0c76d9F26a \
  -vvv
```

This will output:
- Expected deployed addresses
- Gas estimates
- Save transaction data to `broadcast/Deploy.s.sol/<chain_id>/dry-run/run-latest.json`

### Step 2: Extract calldata to individual files

```bash
# Create calldata directory
mkdir -p calldata

# Extract each transaction's calldata
cat broadcast/Deploy.s.sol/1/dry-run/run-latest.json | jq -r '.transactions[0].transaction.input' > calldata/mainnet-tx1-chainvalidator-impl.txt
cat broadcast/Deploy.s.sol/1/dry-run/run-latest.json | jq -r '.transactions[1].transaction.input' > calldata/mainnet-tx2-chainvalidator-proxy.txt
cat broadcast/Deploy.s.sol/1/dry-run/run-latest.json | jq -r '.transactions[2].transaction.input' > calldata/mainnet-tx3-safeharborregistry.txt
cat broadcast/Deploy.s.sol/1/dry-run/run-latest.json | jq -r '.transactions[3].transaction.input' > calldata/mainnet-tx4-agreementfactory.txt
```

### Step 3: Verify calldata files exist

```bash
ls -la calldata/
# Should show files with the calldata
```

---

## Bytecode Verification

### Compiled Bytecode Hashes (keccak256)

```
TX 1 - ChainValidator (impl):  0x90bfeb70ec692c4e11e4eb235769b92e388f4fc5a7e42c4e413f0ace39adcaf9
TX 2 - ERC1967Proxy:           0xf1afa82ac5c36a438632ab0e10a77f5e893fbf2f02c28dd4d5f86b2d131a0c16
TX 3 - SafeHarborRegistry:     0x693274ef32ef653f1741c68831616482b15903c888cdb244ec6654d89218e165
TX 4 - AgreementFactory:       0x29834f1670a28c0621da936843585ce8ebd1f08908af48c8d6085e367cc54883
```

### How to Verify Bytecode

**Step 1: Recompile locally**
```bash
cd registry-contracts
forge build
```

**Step 2: Get bytecode hash**
```bash
# Custom contracts
forge inspect ChainValidator bytecode | cast keccak
forge inspect SafeHarborRegistry bytecode | cast keccak
forge inspect AgreementFactory bytecode | cast keccak

# ERC1967Proxy (from OpenZeppelin - use build artifact)
cat out/ERC1967Proxy.sol/ERC1967Proxy.json | jq -r '.bytecode.object' | cast keccak
```

**Step 3: Compare with deployed**
After deployment, verify on-chain bytecode matches:
```bash
cast code <DEPLOYED_ADDRESS> --rpc-url $RPC_URL | cast keccak
```

### Verification Summary for Others

```
To verify the deployment bytecode matches source:
1. Clone: git clone --recursive https://github.com/security-alliance/safe-harbor.git
2. Checkout the deployment commit/tag
3. Build: cd registry-contracts && forge build
4. Get hash: forge inspect <ContractName> bytecode | cast keccak
5. Compare with deployed: cast code <ADDRESS> --rpc-url $RPC_URL | cast keccak
```

---

## Submitting via Gnosis Safe

### Option A: Transaction Builder (Manual)

1. Go to [Safe App](https://app.safe.global/)
2. Select Safe: `0xD9b8653Ab0bBa82C397b350F7319bA0c76d9F26a`
3. New Transaction → Transaction Builder
4. For each transaction (TX 1-4):
   - **To:** `0xba5Ed099633D3B313e4D5F7bdc1305d3c28ba5Ed`
   - **Value:** `0`
   - **Data:** Copy from appropriate `calldata/*-tx{N}-*.txt` file
5. Submit all 4 transactions in order

### Option B: Using Frame Wallet

If using [Frame](https://frame.sh/) with your Safe connected:

```bash
forge script script/Deploy.s.sol:DeploySafeHarbor \
  --rpc-url http://127.0.0.1:1248 \
  --sender 0xD9b8653Ab0bBa82C397b350F7319bA0c76d9F26a \
  --broadcast
```

Frame will queue the transactions in your Safe for signing.

---

## Post-Deployment Verification

After all 4 transactions are executed:

```bash
# Verify contracts are deployed at expected addresses
cast code 0x1eee8E721816CD5A0033FBA6Ba93486C074dD1cB --rpc-url $RPC_URL  # ChainValidator impl
cast code 0xd01C76ccE414d9B0a294abAFD94feD2e0B88675D --rpc-url $RPC_URL  # ChainValidator proxy
cast code 0x326733493E143b8904716E7A64A9f4fb6A185a2c --rpc-url $RPC_URL  # SafeHarborRegistry
cast code 0xcf317fE605397bC3fae6DAD06331aE5154F277fF --rpc-url $RPC_URL  # AgreementFactory
```

Each should return non-empty bytecode.
