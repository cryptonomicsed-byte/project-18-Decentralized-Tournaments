const hre = require("hardhat");

async function main() {
  console.log("🚀 Deploying Decentralized Tournaments...\n");

  // Get deployer
  const [deployer] = await hre.ethers.getSigners();
  console.log(`Deploying from: ${deployer.address}`);

  // Deploy TournamentFactory
  console.log("\n📦 Deploying TournamentFactory...");
  const TournamentFactory = await hre.ethers.getContractFactory("TournamentFactory");
  const arbitrationFund = process.env.ARBITRATION_FUND || deployer.address;
  
  const factory = await TournamentFactory.deploy(arbitrationFund);
  await factory.deployed();
  
  console.log(`✅ TournamentFactory deployed to: ${factory.address}`);
  console.log(`   Arbitration Fund: ${arbitrationFund}`);

  // Verify creation fee
  const creationFee = await factory.creationFee();
  console.log(`   Creation Fee: ${hre.ethers.utils.formatEther(creationFee)} ETH`);

  // Save deployment info
  const deployment = {
    network: hre.network.name,
    timestamp: new Date().toISOString(),
    factory: factory.address,
    arbitrationFund: arbitrationFund,
    deployer: deployer.address,
  };

  console.log("\n📋 Deployment Info:");
  console.log(JSON.stringify(deployment, null, 2));

  // Save to file
  const fs = require("fs");
  fs.writeFileSync(
    "./deployment.json",
    JSON.stringify(deployment, null, 2)
  );

  console.log("\n✅ Deployment saved to deployment.json");
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
