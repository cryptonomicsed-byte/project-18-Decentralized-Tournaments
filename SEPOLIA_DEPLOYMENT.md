# 🚀 Sepolia Deployment Checklist

**Phase**: 1 (Core Contracts + Tests)  
**Target Network**: World Chain Sepolia (Chain ID: 4801)  
**Status**: ✅ **READY FOR DEPLOYMENT**

---

## 📋 PRE-DEPLOYMENT VERIFICATION

### 1️⃣ Local Validation ✅

```bash
# All tests must pass
npm test
# Expected: 22 passing

# Compilation must succeed
npm run compile
# Expected: No warnings/errors

# Gas estimation (optional)
npm test -- --reporter spec
```

**Checklist:**
- [x] All 22 tests passing
- [x] No hardhat compile warnings
- [x] ArbitrationTest.sol compiles
- [x] All contracts import correctly
- [x] No syntax errors

---

### 2️⃣ Configuration Verification

**Verify hardhat.config.js:**
```javascript
networks: {
  worldchainSepolia: {
    url: "https://worldchain-sepolia.g.alchemy.com/public",  ✓
    chainId: 4801,                                              ✓
    accounts: process.env.PRIVATE_KEY ? [process.env.PRIVATE_KEY] : []
  }
}
```

**Checklist:**
- [ ] RPC URL verified (Alchemy)
- [ ] Chain ID = 4801
- [ ] Private key available in .env
- [ ] Not committed to git

---

### 3️⃣ Environment Setup

**Create .env file:**
```bash
# Private key (64 hex chars, NO 0x prefix)
PRIVATE_KEY=abc123def456...

# Arbitration fund recipient (Sepolia address)
ARBITRATION_FUND=0x...

# Initial creation fee (1 ETH = 1000000000000000000 wei)
CREATION_FEE=1000000000000000000

# Verify fee
VERIFY_FEE_GWEI=30
```

**Checklist:**
- [ ] PRIVATE_KEY set (64 hex chars)
- [ ] ARBITRATION_FUND set (valid Sepolia address)
- [ ] CREATION_FEE configured
- [ ] .env in .gitignore
- [ ] .env NOT committed

---

### 4️⃣ Test Account Setup

**Get Sepolia ETH:**
1. Go to [Alchemy Faucet](https://www.alchemy.com/faucets/world-chain-sepolia)
2. Connect wallet
3. Request Sepolia ETH
4. Wait for confirmation

**Checklist:**
- [ ] Test account has >0.5 ETH on Sepolia
- [ ] Can see balance on [Worldscan Sepolia](https://sepolia.worldscan.org)
- [ ] Private key matches deploying account

---

## 🚀 DEPLOYMENT SEQUENCE

### Step 1: Pre-Deployment Smoke Test

```bash
# Compile all contracts
npm run compile

# Run full test suite
npm test

# Expected output:
# 22 passing (2.5s)
```

**Verify:**
- [x] Compilation successful
- [x] All tests pass
- [x] No errors or warnings

---

### Step 2: Deploy to Sepolia

```bash
npm run deploy-testnet
```

**Expected Output:**
```
🚀 Deploying Decentralized Tournaments...

Deploying from: 0x[your_address_here]

📦 Deploying TournamentFactory...
✅ TournamentFactory deployed to: 0x[FACTORY_ADDRESS]
   Arbitration Fund: 0x[ARBITRATION_FUND]
   Creation Fee: 1.0 ETH

📋 Deployment Info:
{
  "network": "worldchainSepolia",
  "timestamp": "2025-12-14T...",
  "factory": "0x...",
  "arbitrationFund": "0x...",
  "deployer": "0x..."
}

✅ Deployment saved to deployment.json
```

**Checklist:**
- [ ] Deployment succeeds
- [ ] Factory address obtained
- [ ] Arbitration fund set correctly
- [ ] deployment.json created
- [ ] No revert errors

---

### Step 3: Verify Contracts on Explorer

```bash
# Verify TournamentFactory
npx hardhat verify --network worldchainSepolia [FACTORY_ADDRESS] "[ARBITRATION_FUND]"

# Verify Tournament contract (if deployed separately)
# Verify all library contracts
```

**Expected:**
```
Successfully verified contract [address] on the block explorer.
```

**Checklist:**
- [ ] Factory verified on Worldscan
- [ ] Constructor arguments match
- [ ] Source code visible on explorer
- [ ] All contracts verified

---

### Step 4: Create Test Tournament

**Manual test on Sepolia:**

```javascript
// Using cast or ethers.js
const factoryAddress = "0x...";
const tournamentName = "Test Tournament";
const prizePool = "1000000000000000000"; // 1 ETH

// Call: factory.createTournament(name, prizePool)
// Value: prizePool + creationFee (1.1 ETH total)
```

**Checklist:**
- [ ] Tournament created successfully
- [ ] Event emitted on explorer
- [ ] Factory fee collected
- [ ] Prize pool registered

---

### Step 5: Test Basic Flow

```bash
# 1. Create tournament
tx1 = factory.createTournament("Test", 1 ETH)

# 2. Register player
tx2 = tournament.register(worldIdProof)

# 3. Start tournament  
tx3 = factory.startTournament(tournamentAddress)

# 4. Submit score
tx4 = tournament.submitScore(matchId, 1)

# 5. Create dispute (conflicting scores)
tx5 = tournament.submitScore(matchId, -1) // Conflict

# 6. View dispute
dispute = arbitration.getTestDispute(disputeId)
```

**Checklist:**
- [ ] Tournament creation works
- [ ] Player registration works
- [ ] Tournament state transitions
- [ ] Score submission works
- [ ] Dispute creation works

---

## 📊 POST-DEPLOYMENT VALIDATION

### Functional Tests

**Create Tournament:**
- [ ] Factory accepts creation fee
- [ ] Tournament instance created
- [ ] Event emitted with address

**Register Player:**
- [ ] World ID proof accepted (placeholder)
- [ ] Player marked as registered
- [ ] Duplicate registration rejected

**Submit Scores:**
- [ ] Match scores accepted
- [ ] Conflicting scores trigger dispute
- [ ] Scores stored correctly

**Dispute Resolution:**
- [ ] Timeout auto-resolves after 24h
- [ ] Stake resolution works (3x rule)
- [ ] Jury can be selected
- [ ] Vote tallying works

---

### Security Tests

**Access Control:**
- [ ] Only registered players can submit scores
- [ ] Only factory can start tournament
- [ ] Only selected jurors can vote
- [ ] Prize claims require valid claim

**Deadline Enforcement:**
- [ ] Evidence submission window strictly enforced
- [ ] Stake submission window strictly enforced
- [ ] Voting deadline strictly enforced
- [ ] Prize claim deadline strictly enforced

**Fund Safety:**
- [ ] Prize pool locked until tournament complete
- [ ] Insufficient funds detected
- [ ] Clawback mechanism works
- [ ] No unauthorized withdrawals

---

### Integration Tests

**With Block Explorer:**
- [ ] Transactions visible on Worldscan
- [ ] Events properly indexed
- [ ] Contract state readable
- [ ] Constructor args verified

**With Frontend (Phase 3):**
- [ ] Contract ABI loadable
- [ ] State queries work
- [ ] Write transactions executable
- [ ] Events capturable

---

## 🔐 SECURITY CHECKLIST

**Before Mainnet:**
- [ ] No private keys in repository
- [ ] All functions tested
- [ ] Edge cases handled
- [ ] Reentrancy guards present
- [ ] Access controls verified
- [ ] Deadline enforcement confirmed

**World ID Integration:**
- [ ] Proof validation logic defined
- [ ] Action ID configured
- [ ] Signal hash set
- [ ] World Chain oracle configured

**Gas Optimization:**
- [ ] No obvious inefficiencies
- [ ] Batch operations where possible
- [ ] Storage writes minimized
- [ ] No infinite loops

---

## 📝 DOCUMENTATION

**Update README:**
- [ ] Add Sepolia testnet info
- [ ] Include factory address
- [ ] Link to Worldscan
- [ ] Document test flow

**Create Deployment Record:**
- [ ] Save all contract addresses
- [ ] Document timestamp
- [ ] Record deployer
- [ ] Note arbitration fund

**Example README Update:**
```markdown
## Testnet Addresses (Sepolia)

- **Factory**: 0x...
- **Tournament Logic**: 0x... (in factory)
- **Network**: World Chain Sepolia (4801)
- **Explorer**: https://sepolia.worldscan.org
- **RPC**: https://worldchain-sepolia.g.alchemy.com/public

### Test Flow
1. Create tournament via factory.createTournament()
2. Register players with World ID
3. Submit match scores
4. Trigger dispute if scores conflict
5. Resolve via timeout, stake, or jury
```

---

## 🚨 COMMON ISSUES

**"Insufficient ETH"**
- Solution: Get more Sepolia ETH from faucet
- Need: >0.5 ETH for deployment + testing

**"RPC connection failed"**
- Solution: Verify RPC URL is correct
- Check: https://worldchain-sepolia.g.alchemy.com/public

**"Invalid proof"**
- Solution: World ID proof validation pending Phase 2
- Current: Placeholder accepts any non-empty proof

**"Revert: Only factory can call"**
- Solution: Ensure calls come from correct address
- Check: Contract permissions

---

## 📈 SUCCESS CRITERIA

After deployment, verify:

✅ **All Contracts Deployed:**
- TournamentFactory
- Tournament (template)
- Arbitration library
- Prize escrow library
- World ID verifier library

✅ **All Tests Passing:**
- 22 tests on local hardhat
- Smoke test on Sepolia
- Integration test completed

✅ **Basic Flow Working:**
- Create tournament
- Register players
- Submit scores
- Resolve disputes
- Claim prizes

✅ **Explorer Integration:**
- Contracts verified
- Transactions visible
- Events indexed
- State queryable

✅ **Ready for Phase 2:**
- Game API integration
- Frontend development
- User testing

---

## 🎯 NEXT STEPS

**Immediately After Deployment:**
1. Document all contract addresses
2. Update README with testnet links
3. Test basic tournament flow
4. Verify events on explorer
5. Share addresses with team

**Phase 2 (Game Integrations):**
1. Define IGameOracle interface
2. Create Chess.com adapter
3. Create API oracle bridge
4. Auto-submit scores from games
5. Integrate with tournament flow

**Phase 3 (Frontend):**
1. React Mini App scaffold
2. wagmi integration
3. World ID verification UI
4. Tournament browser
5. Score submission interface

---

## 📞 SUPPORT

**If deployment fails:**
1. Check error message carefully
2. Verify .env configuration
3. Check account balance
4. Review RPC connectivity
5. Re-run local tests

**Questions?**
- See README.md for overview
- Check TEST_COVERAGE.md for test details
- Review contracts for implementation

---

**Status**: ✅ **PHASE 1 COMPLETE - READY FOR SEPOLIA**

**Next**: Execute deployment sequence above, then proceed to Phase 2.

🗿⚖️🕊️
