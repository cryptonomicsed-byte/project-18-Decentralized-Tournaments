#!/bin/bash

# Decentralized Tournaments - Quick Deployment Script
# Usage: bash DEPLOY_COMMANDS.sh

set -e

echo "🚀 DECENTRALIZED TOURNAMENTS - SEPOLIA DEPLOYMENT"
echo "=================================================="
echo ""

# Step 1: Verify environment
echo "📋 Step 1: Verifying environment..."
if [ ! -f ".env" ]; then
    echo "❌ ERROR: .env file not found"
    echo "   Please create .env with:"
    echo "   - PRIVATE_KEY=your_64_hex_chars"
    echo "   - ARBITRATION_FUND=0x..."
    exit 1
fi

PRIVATE_KEY=$(grep "PRIVATE_KEY" .env | cut -d '=' -f2 | tr -d ' ')
if [ -z "$PRIVATE_KEY" ]; then
    echo "❌ ERROR: PRIVATE_KEY not set in .env"
    exit 1
fi
echo "✅ .env configured"
echo ""

# Step 2: Install dependencies
echo "📦 Step 2: Installing dependencies..."
npm install --silent
echo "✅ Dependencies installed"
echo ""

# Step 3: Compile contracts
echo "🔨 Step 3: Compiling contracts..."
npm run compile
if [ $? -ne 0 ]; then
    echo "❌ Compilation failed"
    exit 1
fi
echo "✅ Contracts compiled"
echo ""

# Step 4: Run tests
echo "🧪 Step 4: Running test suite..."
npm test
if [ $? -ne 0 ]; then
    echo "❌ Tests failed"
    exit 1
fi
echo "✅ All tests passed"
echo ""

# Step 5: Deploy to Sepolia
echo "🌐 Step 5: Deploying to Sepolia..."
npm run deploy-testnet
if [ $? -ne 0 ]; then
    echo "❌ Deployment failed"
    exit 1
fi
echo "✅ Deployment successful"
echo ""

# Step 6: Read deployment info
if [ -f "deployment.json" ]; then
    echo "📊 Deployment Info:"
    cat deployment.json
    echo ""
    
    FACTORY_ADDRESS=$(grep -o '"factory":"[^"]*' deployment.json | cut -d'"' -f4)
    echo "📍 Factory Address: $FACTORY_ADDRESS"
    echo "🔗 Explorer: https://sepolia.worldscan.org/address/$FACTORY_ADDRESS"
    echo ""
fi

echo "✅ DEPLOYMENT COMPLETE!"
echo ""
echo "📚 Next steps:"
echo "  1. Verify contracts on explorer"
echo "  2. Create test tournament"
echo "  3. Register test players"
echo "  4. Test dispute resolution"
echo "  5. Review Game API integration (Phase 2)"
echo ""
echo "🗿⚖️🕊️"
