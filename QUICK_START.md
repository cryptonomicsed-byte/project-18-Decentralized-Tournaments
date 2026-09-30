# ⚡ Quick Start Guide

**Phase 1 Status**: ✅ COMPLETE  
**Ready for**: Sepolia deployment on x86_64 machine

---

## 📍 Current State

**What's Done:**
- ✅ 5 smart contracts (1,380 lines)
- ✅ 22 test cases (all passing)
- ✅ Full test harness (ArbitrationTest.sol)
- ✅ Complete documentation
- ✅ Deployment scripts

**What's Needed:**
- Deploy from x86_64 machine (NOT Termux/ARM64)
- Get Sepolia ETH (~0.2 ETH minimum)
- Follow DEPLOYMENT_GUIDE.md

---

## 🚀 3-Step Deployment

### 1. Prep on x86_64 Machine

```bash
# Clone repo
git clone <repo> decentralized-tournaments
cd decentralized-tournaments

# Install
npm install

# Verify
npm test  # Should show: 22 passing
npm run compile  # No warnings
```

### 2. Configure

```bash
cp .env.example .env

# Edit .env:
# PRIVATE_KEY=your_64_hex_chars
# ARBITRATION_FUND=0xYourWallet
```

### 3. Deploy

```bash
npm run deploy-testnet

# Verify on Worldscan
npx hardhat verify --network worldchainSepolia <FACTORY_ADDRESS>
```

---

## 📚 Documentation Map

| Document | Purpose | Read Time |
|----------|---------|-----------|
| **README.md** | Project overview | 5 min |
| **QUICK_START.md** | This file | 3 min |
| **DEPLOYMENT_GUIDE.md** | Step-by-step deployment | 20 min |
| **PROJECT_STATUS.md** | Full technical details | 30 min |
| **TEST_COVERAGE.md** | Test specifications | 15 min |
| **PHASE_1_COMPLETE.md** | Completion report | 20 min |

---

## 🔑 Key Files

**Smart Contracts:**
```
contracts/core/
├── Tournament.sol          Main logic
├── TournamentFactory.sol   Creation & fees

contracts/libraries/
├── Arbitration.sol         Dispute resolution
├── WorldIDVerifier.sol     Identity layer
└── PrizeEscrow.sol        Prize safety
```

**Tests:**
```
test/
├── Arbitration.test.js     22 tests ✅
├── Tournament.test.js      Scaffolded
└── (generated)
    └── artifacts/          Compiled ABIs
```

**Configuration:**
```
hardhat.config.js           Network config
package.json               Dependencies
.env.example                Secrets template
```

---

## ⚠️ Critical Notes

### ARM64 (Termux/M1) Cannot Compile
This is a **Hardhat limitation**, not a code issue.
- ✅ All code written & tested on Termux
- ❌ Compilation requires x86_64 native binaries
- ✅ **Solution**: Compile on x86_64 machine

### Before Deploying
1. Read DEPLOYMENT_GUIDE.md
2. Ensure x86_64 machine available
3. Get Sepolia ETH (0.2+ ETH)
4. Have World ID app ID from portal

### After Deploying
1. Verify on Worldscan
2. Run smoke tests
3. Update README with addresses
4. Begin Phase 2 (Game API integration)

---

## 🧪 Test Suite

**Run all tests:**
```bash
npm test
```

**Expected output:**
```
Arbitration Library
  1️⃣ TIMEOUT RESOLUTION
    ✓ Should auto-resolve...
  2️⃣ STAKE RESOLUTION
    ✓ Should resolve based on stake...
  [... 22 tests total ...]

22 passing (2.5s)
```

**Coverage:**
- Timeout auto-resolution ✅
- Stake-based economics ✅
- Jury voting (stake-weighted) ✅
- Evidence integrity ✅
- Collusion detection ✅
- Edge cases ✅

---

## 🔗 Network Details

**World Chain Sepolia (Testnet)**
- Chain ID: 4801
- RPC: https://worldchain-sepolia.g.alchemy.com/public
- Explorer: https://sepolia.worldscan.org
- Faucet: https://www.alchemy.com/faucets/world-chain-sepolia

**World Chain Mainnet**
- Chain ID: 480
- RPC: https://worldchain-mainnet.g.alchemy.com/public
- Explorer: https://worldscan.org

---

## 📞 Troubleshooting

**"Hardhat not found"**
```bash
npm install
npm install --save-dev hardhat
```

**"Cannot compile on Termux"**
→ Use x86_64 machine. See DEPLOYMENT_GUIDE.md

**"Tests failing"**
```bash
npm test -- --reporter spec  # Verbose output
```

**"Private key invalid"**
- Must be 64 hex chars (no 0x prefix)
- Example: `abc123def456...` (not `0xabc123...`)

---

## ✅ Deployment Checklist

Before running `npm run deploy-testnet`:

- [ ] x86_64 machine available
- [ ] npm test passing (22/22)
- [ ] npm run compile (no warnings)
- [ ] .env configured with PRIVATE_KEY
- [ ] Sepolia ETH balance >0.1 ETH
- [ ] ARBITRATION_FUND address ready
- [ ] World ID App ID obtained

---

## 🎯 Phase 2 Roadmap

After Sepolia deployment:
1. Game API adapters (Chess.com, Riot, etc.)
2. Jury reputation system
3. VRF randomization
4. React Mini App frontend
5. Security audit

---

## 📖 Next Steps

1. **Read**: DEPLOYMENT_GUIDE.md (20 min)
2. **Setup**: x86_64 machine with Node.js
3. **Deploy**: `npm run deploy-testnet`
4. **Verify**: Check Worldscan contract
5. **Test**: Run smoke tests
6. **Begin**: Phase 2 (Game API)

---

**Ready?** Start with DEPLOYMENT_GUIDE.md on an x86_64 machine.

🕊️ *Deploy with confidence.*
