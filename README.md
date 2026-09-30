# ⚖️ Decentralized Tournaments

Fair, sybil-resistant tournament system on World Chain with World ID verification and dispute resolution.

**Features:**
- ✅ World ID verification (one human = one account)
- ✅ Fair bracket generation (randomized seeding)
- ✅ Multi-stage dispute resolution (timeout → stake → jury)
- ✅ Prize escrow with clawback safety
- ✅ Arbitration fund for resolving disputes

## 🏗️ Architecture

**Smart Contracts:**
- `Tournament.sol` - Main tournament logic, registration, scoring
- `TournamentFactory.sol` - Tournament creation, fee management
- `Arbitration.sol` - Dispute resolution with escalation
- `WorldIDVerifier.sol` - World ID integration library
- `PrizeEscrow.sol` - Safe prize management

**Networks:**
- World Chain (Sepolia Testnet): Chain ID 4801
- World Chain (Mainnet): Chain ID 480

## 📦 Setup

```bash
# Install dependencies
npm install

# Create .env file
cp .env.example .env

# Add your private key and arbitration fund address
# PRIVATE_KEY=your_64_hex_chars_here
# ARBITRATION_FUND=0x...
```

## 🧪 Testing

```bash
# Run all tests
npm test

# Run specific test file
npm test test/Tournament.test.js

# Run with verbose output
npm test -- --reporter spec
```

## 🚀 Deployment

**Testnet:**
```bash
npm run deploy-testnet
```

**Mainnet:**
```bash
npm run deploy
```

## 🎯 MVP Milestones

- [x] Core contract scaffolds
- [x] Arbitration library (timeout → stake → jury)
- [x] Prize escrow safety
- [x] Factory creation & fee collection
- [ ] Arbitration test contracts
- [ ] Game API integrations (Chess, Riot, etc.)
- [ ] Frontend React Mini App
- [ ] World ID native integration

## ⚖️ Dispute Resolution Workflow

1. **Score Submission** (24h window)
   - Players submit match results
   - If scores match: auto-confirm
   - If conflict: escalate to disputes

2. **Evidence Phase** (24h)
   - Players submit proof (video, game logs, etc.)
   - Non-submission = automatic loss

3. **Stake Phase** (24h)
   - Players stake collateral (min 0.1 ETH)
   - 3x differential = auto-resolve (economic truth)
   - Equal stakes → jury voting

4. **Jury Phase** (48h)
   - Community members vote
   - Majority vote determines winner
   - Loser's stake slashed

## 📋 Configuration

**Environment Variables:**
- `PRIVATE_KEY` - Deployment account (64 hex chars, no 0x prefix)
- `ARBITRATION_FUND` - Address receiving arbitration allocations
- `CREATION_FEE` - Tournament creation fee (default: 1 ETH)

**Contract Parameters:**
- Scoring window: 24 hours
- Dispute window: 48 hours
- Claim deadline: 30 days
- Min stake: 0.1 ETH
- Arbitration share: 5% of prize pools

## 🔐 Security

- ✅ Reentrancy guards on prize distribution
- ✅ Pausable tournaments for emergency stop
- ✅ Fee safeguards (min amounts, ratio checks)
- ✅ World ID one-account-per-human enforcement
- ⏳ Professional audit pending (Phase 2)

## 📚 Resources

- [World Chain Docs](https://docs.world.org/)
- [World ID Integration](https://docs.world.org/world-id/integration-guide)
- [OpenZeppelin Contracts](https://docs.openzeppelin.com/contracts/5.x/)
- [Hardhat Documentation](https://hardhat.org/)

## 📄 License

MIT
