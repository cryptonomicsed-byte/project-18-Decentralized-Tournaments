const { expect } = require("chai");

describe("Tournament", function () {
  let factory, tournament;
  let owner, player1, player2;

  beforeEach(async function () {
    [owner, player1, player2] = await ethers.getSigners();

    // Deploy factory
    const TournamentFactory = await ethers.getContractFactory("TournamentFactory");
    factory = await TournamentFactory.deploy(owner.address);
    await factory.deployed();

    // Create tournament
    const tx = await factory.createTournament(
      "Test Tournament",
      ethers.utils.parseEther("1.0"),
      {
        value: ethers.utils.parseEther("1.1"), // 1 ETH pool + 0.1 fee
      }
    );

    const receipt = await tx.wait();
    const event = receipt.events.find((e) => e.event === "TournamentCreated");
    const tournamentAddr = event.args.tournament;

    const Tournament = await ethers.getContractFactory("Tournament");
    tournament = Tournament.attach(tournamentAddr);
  });

  describe("Registration", function () {
    it("Should register player", async function () {
      const proof = ethers.utils.toUtf8Bytes("valid_world_id_proof");
      await tournament.connect(player1).register(proof);

      expect(await tournament.registered(player1.address)).to.be.true;
    });

    it("Should prevent duplicate registration", async function () {
      const proof = ethers.utils.toUtf8Bytes("valid_world_id_proof");
      await tournament.connect(player1).register(proof);

      await expect(
        tournament.connect(player1).register(proof)
      ).to.be.revertedWith("Already registered");
    });

    it("Should reject invalid proof", async function () {
      await expect(
        tournament.connect(player1).register("0x")
      ).to.be.revertedWith("Invalid World ID proof");
    });

    it("Should track player count", async function () {
      const proof = ethers.utils.toUtf8Bytes("valid_world_id_proof");
      
      await tournament.connect(player1).register(proof);
      expect(await tournament.getPlayerCount()).to.equal(1);

      await tournament.connect(player2).register(proof);
      expect(await tournament.getPlayerCount()).to.equal(2);
    });
  });

  describe("Tournament State", function () {
    it("Should start in Registration status", async function () {
      expect(await tournament.status()).to.equal(0); // Registration
    });

    it("Should transition to Active", async function () {
      const proof = ethers.utils.toUtf8Bytes("valid_world_id_proof");
      await tournament.connect(player1).register(proof);
      await tournament.connect(player2).register(proof);

      await factory.startTournament(await tournament.getAddress());

      expect(await tournament.status()).to.equal(1); // Active
    });

    it("Should prevent start with insufficient players", async function () {
      const proof = ethers.utils.toUtf8Bytes("valid_world_id_proof");
      await tournament.connect(player1).register(proof);

      await expect(
        factory.startTournament(await tournament.getAddress())
      ).to.be.revertedWith("Need at least 2 players");
    });
  });

  describe("Prize Distribution", function () {
    it("Should distribute prizes", async function () {
      const prizeAmount = ethers.utils.parseEther("0.5");
      
      await tournament.distributePrize(
        player1.address,
        prizeAmount
      );

      const prize = await tournament.prizes(player1.address);
      expect(prize).to.equal(prizeAmount);
    });

    it("Should prevent overfull distribution", async function () {
      const excessPrize = ethers.utils.parseEther("1.5"); // Pool is 1 ETH

      await expect(
        tournament.distributePrize(player1.address, excessPrize)
      ).to.be.revertedWith("Insufficient pool");
    });
  });

  describe("Pause/Unpause", function () {
    it("Should pause tournament", async function () {
      await tournament.pause();
      
      const proof = ethers.utils.toUtf8Bytes("valid_world_id_proof");
      await expect(
        tournament.connect(player1).register(proof)
      ).to.be.revertedWith("Pausable: paused");
    });

    it("Should unpause tournament", async function () {
      await tournament.pause();
      await tournament.unpause();
      
      const proof = ethers.utils.toUtf8Bytes("valid_world_id_proof");
      await expect(
        tournament.connect(player1).register(proof)
      ).to.not.be.reverted;
    });
  });
});
