// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/**
 * @title TournamentFactory
 * @dev Factory for creating and managing tournament instances
 * @notice Handles tournament creation, fee collection, and arbitration fund management
 */

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./Tournament.sol";

contract TournamentFactory is Ownable, ReentrancyGuard {
    
    // ========== STATE VARIABLES ==========
    
    address public arbitrationFund;
    uint256 public creationFee = 1 ether; // Sybil deterrent
    uint256 public arbitrationFundShare = 5; // 5% of prize pools
    
    Tournament[] public tournaments;
    mapping(address => uint256[]) public creatorTournaments;
    mapping(address => bool) public verifiedCreators;
    
    // ========== EVENTS ==========
    
    event TournamentCreated(
        address indexed creator,
        address indexed tournament,
        string name,
        uint256 prizePool
    );
    event CreationFeeUpdated(uint256 newFee);
    event ArbitrationFundUpdated(address newFund);
    
    // ========== MODIFIERS ==========
    
    modifier verifiedOnly() {
        require(verifiedCreators[msg.sender] || msg.sender == owner(), "Creator not verified");
        _;
    }
    
    // ========== CONSTRUCTOR ==========
    
    constructor(address _arbitrationFund) {
        require(_arbitrationFund != address(0), "Invalid fund address");
        arbitrationFund = _arbitrationFund;
        verifiedCreators[msg.sender] = true; // Owner can create tournaments
    }
    
    // ========== TOURNAMENT CREATION ==========
    
    /**
     * @dev Create a new tournament
     * @param _name Tournament name
     * @param _prizePool Total prize pool (must be sent as ETH)
     */
    function createTournament(
        string calldata _name,
        uint256 _prizePool
    ) external payable verifiedOnly nonReentrant returns (address) {
        require(msg.value == _prizePool + creationFee, "Incorrect ETH amount");
        require(_prizePool > 0, "Prize pool must be > 0");
        require(bytes(_name).length > 0, "Name required");
        require(bytes(_name).length <= 100, "Name too long");
        
        // Create tournament instance
        Tournament tournament = new Tournament(
            address(this),
            _name,
            _prizePool
        );
        
        // Track tournament
        tournaments.push(tournament);
        creatorTournaments[msg.sender].push(tournaments.length - 1);
        
        // Process fees
        _processFees(_prizePool, msg.sender);
        
        // Transfer prize pool to tournament
        (bool success, ) = payable(address(tournament)).call{value: _prizePool}("");
        require(success, "Prize pool transfer failed");
        
        emit TournamentCreated(msg.sender, address(tournament), _name, _prizePool);
        
        return address(tournament);
    }
    
    /**
     * @dev Process creation fee and arbitration fund allocation
     */
    function _processFees(uint256 _prizePool, address _creator) internal {
        uint256 arbitrationAllocation = (_prizePool * arbitrationFundShare) / 100;
        uint256 creatorRebate = arbitrationAllocation / 2;
        
        // Send arbitration allocation to fund
        (bool success1, ) = payable(arbitrationFund).call{value: arbitrationAllocation}("");
        require(success1, "Arbitration fund transfer failed");
        
        // Keep creation fee (minus rebate)
        // Rebate incentivizes verified creators
        if (creatorRebate > 0) {
            (bool success2, ) = payable(_creator).call{value: creatorRebate}("");
            require(success2, "Rebate transfer failed");
        }
    }
    
    // ========== CREATOR VERIFICATION ==========
    
    /**
     * @dev Whitelist a creator (owner only)
     */
    function verifyCreator(address _creator) external onlyOwner {
        require(_creator != address(0), "Invalid address");
        verifiedCreators[_creator] = true;
    }
    
    /**
     * @dev Remove creator verification (owner only)
     */
    function revokeCreator(address _creator) external onlyOwner {
        verifiedCreators[_creator] = false;
    }
    
    // ========== CONFIGURATION ==========
    
    /**
     * @dev Update creation fee (owner only)
     */
    function setCreationFee(uint256 _newFee) external onlyOwner {
        creationFee = _newFee;
        emit CreationFeeUpdated(_newFee);
    }
    
    /**
     * @dev Update arbitration fund address (owner only)
     */
    function setArbitrationFund(address _newFund) external onlyOwner {
        require(_newFund != address(0), "Invalid address");
        arbitrationFund = _newFund;
        emit ArbitrationFundUpdated(_newFund);
    }
    
    /**
     * @dev Update arbitration fund share percentage
     */
    function setArbitrationFundShare(uint256 _percentage) external onlyOwner {
        require(_percentage <= 10, "Share too high");
        arbitrationFundShare = _percentage;
    }
    
    // ========== VIEW FUNCTIONS ==========
    
    function getTournamentCount() external view returns (uint256) {
        return tournaments.length;
    }
    
    function getTournament(uint256 _index) external view returns (address) {
        require(_index < tournaments.length, "Invalid index");
        return address(tournaments[_index]);
    }
    
    function getCreatorTournaments(address _creator) external view returns (uint256[] memory) {
        return creatorTournaments[_creator];
    }
    
    function isVerifiedCreator(address _creator) external view returns (bool) {
        return verifiedCreators[_creator];
    }
    
    // Receive ETH
    receive() external payable {}
}
