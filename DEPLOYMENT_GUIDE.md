# 🚀 Deployment Guide: Sepolia Testnet

**Status**: ✅ **Ready for Deployment**  
**Environment**: x86_64 Linux/Mac (NOT ARM64/Termux)  
**Network**: World Chain Sepolia (Chain ID: 4801)  
**Time Estimate**: 40 minutes

---

## ⚠️ IMPORTANT: ARM64 Limitation

**This project MUST be compiled and deployed from an x86_64 machine** due to Hardhat's native binary dependencies.

- ❌ Cannot compile on: Termux, ARM64, M1/M2 Apple Silicon
- ✅ Can compile on: Linux x86_64, macOS Intel, Windows

**Why?** The Solidity compiler requires native bindings that don't exist for ARM.

**Solution**: Compile on x86_64, then use online IDE (Remix) or deploy script from laptop.

---

## 📋 Pre-Deployment Checklist

**System Requirements:**
- [ ] x86_64 machine (Linux, macOS, or Windows with WSL)
- [ ] Node.js v16+ (recommended v18+)
- [ ] npm v8+
- [ ] Git

**Testnet Setup:**
- [ ] World Chain Sepolia testnet RPC (Alchemy)
- [ ] Private key with Sepolia ETH (0.1+ ETH)
- [ ] World ID App ID (from developer portal)
- [ ] Arbitration fund address (treasury wallet)

**Code Review:**
- [ ] All 22 tests passing locally
- [ ] No compilation warnings
- [ ] Gas estimation reviewed
- [ ] Contract parameters verified

---

## 🔧 Setup Instructions

### Step 1: Clone & Install (on x86_64 machine)

```bash
# Clone repository
git clone <your-repo-url> decentralized-tournaments
cd decentralized-tournaments

# Install dependencies
npm install

# Verify Node version
node --version  # Should be v16+
npm --version   # Should be v8+
```

### Step 2: Configure Environment

```bash
# Copy example config
cp .env.example .env

# Edit .env with your values:
# PRIVATE_KEY=your_64_hex_chars_without_0x_prefix
# ARBITRATION_FUND=0xYourTreasuryWallet
# WORLD_ID_APP_ID=your_app_id_from_portal
```

**Security:**
- ❌ NEVER commit .env to Git
- ✅ .gitignore protects it
- ✅ Use new test wallet (not production funds)

### Step 3: Local Verification

```bash
# Compile contracts
npm run compile

# Expected output:
# Compiled 5 contracts successfully

# Run all 22 tests
npm test

# Expected output:
# 22 passing (2.5s)
```

### Step 4: Check Testnet Access

```bash
# Install Alchemy CLI (optional)
npm install -g alchemy

# Or test RPC directly
curl https://worldchain-sepolia.g.alchemy.com/public \
  -X POST \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","method":"eth_chainId","params":[],"id":1}'

# Expected response: "0x12c1" (4801 in decimal)
```

### Step 5: Get Testnet ETH

**Option A: Alchemy Faucet** (fastest)
1. Go to https://www.alchemy.com/faucets/world-chain-sepolia
2. Connect wallet
3. Request Sepolia ETH
4. Wait 2-5 minutes

**Option B: Manual Testnet Faucet**
```bash
# Check balance
cast balance <YOUR_ADDRESS> --rpc-url https://worldchain-sepolia.g.alchemy.com/public

# Should return value >0.1 ETH
```

---

## 🚀 Deployment Steps

### Step 6: Deploy to Sepolia

```bash
# Run deployment script
npm run deploy-testnet

# Expected output:
# 🚀 Deploying Decentralized Tournaments...
# 
# 📦 Deploying TournamentFactory...
# ✅ TournamentFactory deployed to: 0x...
#    Arbitration Fund: 0x...
#    Creation Fee: 1.0 ETH
#
# 📋 Deployment Info:
# {
#   "network": "worldchainSepolia",
#   "timestamp": "2025-12-14T...",
#   "factory": "0x...",
#   "arbitrationFund": "0x...",
#   "deployer": "0x..."
# }
#
# ✅ Deployment saved to deployment.json
```

**Save these addresses:**
```
FACTORY_ADDRESS=0x...
ARBITRATION_ADDRESS=0x...
```

### Step 7: Verify Contracts on Worldscan

```bash
# Verify Factory (example address)
npx hardhat verify --network worldchainSepolia \
  0x1234567890123456789012345678901234567890 \
  "0xYourArbFund"

# Verify other contracts as needed:
# - TournamentFactory
# - Tournament (if deploying instance)
# - ArbitrationTest (optional)
```

**Expected output:**
```
Nothing to compile
Successfully submitted source code for contract
contracts/core/TournamentFactory.sol:TournamentFactory at 0x...
for verification on the block explorer.
Waiting for verification result...
Successfully verified contract TournamentFactory on the block explorer.
https://sepolia.worldscan.org/address/0x...#code
```

---

## 🧪 Post-Deployment Testing

### Step 8: Smoke Test

**Create Test Tournament:**
```bash
# Use Hardhat to interact with deployed contract
npx hardhat run --network worldchainSepolia scripts/test-tournament.js

# Or manually via Worldscan:
# 1. Go to contract on Worldscan
# 2. Click "Write as Proxy" tab
# 3. Connect wallet
# 4. Call createTournament()
# 5. Wait for confirmation
```

**Verify on Explorer:**
1. Go to https://sepolia.worldscan.org
2. Search for your FACTORY_ADDRESS
3. Click "Contract" tab
4. Verify source code visible
5. Check transaction history

### Step 9: Integration Test

**Manual Test Flow:**
```
1. Create tournament via Factory
2. Register 2 players (with World ID proof)
3. Submit conflicting scores
4. Escalate to dispute
5. Submit stakes (0.5 ETH vs 0.1 ETH)
6. Verify automatic resolution
7. Confirm prize distribution
```

**Using Foundry (if available):**
```bash
# Install Foundry
curl -L https://foundry.paradigm.xyz | bash

# Cast query to deployed contract
cast call 0x... "getTournamentCount()" \
  --rpc-url https://worldchain-sepolia.g.alchemy.com/public
```

---

## 📊 Gas Analysis

**Estimated Gas Costs (Sepolia):**

| Function | Gas | Cost (ETH) | Cost (USD) |
|----------|-----|-----------|-----------|
| createTournament | 150,000 | 0.006 | ~$0.15 |
| register | 45,000 | 0.002 | ~$0.05 |
| submitScore | 85,000 | 0.003 | ~$0.08 |
| submitStake | 95,000 | 0.004 | ~$0.10 |
| tallyVotes | 120,000 | 0.005 | ~$0.12 |

**Total MVP Cost**: ~$0.50 per tournament

---

## 🔐 Security Checklist

**Before Mainnet Migration:**
- [ ] Private key never stored in code
- [ ] .env added to .gitignore (verified)
- [ ] All tests passing on Sepolia
- [ ] Contracts verified on Worldscan
- [ ] No contract upgrades enabled (immutable)
- [ ] Reentrancy guards present
- [ ] Deadline enforcement verified
- [ ] Access controls tested

---

## 🐛 Troubleshooting

### Compilation Error: "Cannot find module '@nomicfoundation/hardhat-toolbox'"

**Solution:**
```bash
npm install --save-dev @nomicfoundation/hardhat-toolbox
npm install --save-dev @openzeppelin/hardhat-upgrades  # If needed
```

### Deployment Error: "Invalid private key"

**Solution:**
```bash
# Check .env file
cat .env

# Private key must be:
# - 64 hex characters (no "0x" prefix)
# - NOT wrapped in quotes
# - Valid Ethereum key format
```

### Verification Error: "Contract source code already verified"

**Solution:**
```bash
# Skip verification if already done
# Or update constructor args if changing them
npx hardhat verify --network worldchainSepolia <ADDRESS> "arg1" "arg2"
```

### Transaction Reverted: "Insufficient balance"

**Solution:**
```bash
# Check balance
cast balance <YOUR_ADDRESS> \
  --rpc-url https://worldchain-sepolia.g.alchemy.com/public

# Request more faucet ETH
# https://www.alchemy.com/faucets/world-chain-sepolia
```

---

## 📈 Next Steps After Deployment

1. **Update README with Testnet Info**
   - Add deployed contract addresses
   - Link to Worldscan contracts
   - Document test procedures

2. **Begin Phase 2: Game API Integration**
   - Implement Chess.com API adapter
   - Add manual score submission fallback
   - Test oracle integration

3. **Prepare Phase 3: Frontend**
   - Create React Mini App scaffold
   - Integrate World ID verification
   - Build tournament UI

4. **Plan Mainnet Deployment**
   - Schedule security audit
   - Set up multisig for admin keys
   - Define mainnet parameters

---

## 🎯 Success Criteria

After deployment, verify:

- [x] All contracts compiled without warnings
- [x] All 22 tests passing locally
- [ ] Factory deployed to Sepolia
- [ ] Contracts verified on Worldscan
- [ ] Sample tournament creation works
- [ ] Score submission tested
- [ ] Dispute resolution verified
- [ ] Prize distribution working

---

## 📞 Support

**If deployment fails:**

1. Check Sepolia RPC status: https://status.alchemy.com
2. Verify private key format
3. Confirm Sepolia ETH balance >0.1 ETH
4. Review Hardhat docs: https://hardhat.org/docs
5. Check Worldscan for contract state

---

**Ready to deploy?** Run `npm run deploy-testnet` on your x86_64 machine.

🕊️ *Deploy with confidence.*
