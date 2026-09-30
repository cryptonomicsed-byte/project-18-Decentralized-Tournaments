// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/**
 * @title Tournament
 * @dev Core tournament contract with World ID verification and dispute resolution
 * @notice Manages registration, scoring, and prize distribution for a single tournament
 */

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

contract Tournament is Ownable, ReentrancyGuard, Pausable {
    
    // ========== STATE ENUMS & STRUCTURES ==========
    
    enum Status { Registration, Active, Disputed, Complete }
    
    struct DisputeData {
        address plaintiff;
        address defendant;
        uint256 matchId;
        bytes evidence;
        uint256 deadline;
        bool resolved;
        address winner;
    }
    
    struct Match {
        address player1;
        address player2;
        int8 score1;
        int8 score2;
        uint256 submissionDeadline;
        bool confirmed;
        bool disputed;
    }
    
    // ========== STATE VARIABLES ==========
    
    address public immutable factory;
    uint256 public immutable createdAt;
    
    Status public status;
    string public tournamentName;
    uint256 public prizePool;
    
    // World ID tracking
    mapping(address => bool) public registered;
    address[] public players;
    
    // Match data
    mapping(uint256 => Match) public matches;
    uint256 public matchCount;
    
    // Dispute mechanism
    mapping(uint256 => DisputeData) public disputes;
    uint256 public disputeCount;
    
    // Prize tracking
    mapping(address => uint256) public prizes;
    uint256 public claimDeadline;
    
    // Configuration
    uint256 public scoringWindow = 24 hours;
    uint256 public disputeWindow = 48 hours;
    
    // ========== EVENTS ==========
    
    event PlayerRegistered(address indexed player, uint256 timestamp);
    event ScoreSubmitted(uint256 indexed matchId, address indexed player, int8 score);
    event DisputeEscalated(uint256 indexed disputeId, uint256 indexed matchId);
    event PrizeDistributed(address indexed winner, uint256 amount);
    event TournamentStatusChanged(Status newStatus);
    
    // ========== MODIFIERS ==========
    
    modifier onlyFactory() {
        require(msg.sender == factory, "Only factory can call this");
        _;
    }
    
    modifier onlyRegistered() {
        require(registered[msg.sender], "Player not registered");
        _;
    }
    
    modifier onlyActive() {
        require(status == Status.Active, "Tournament not active");
        _;
    }
    
    // ========== CONSTRUCTOR ==========
    
    constructor(
        address _factory,
        string memory _name,
        uint256 _prizePool
    ) {
        factory = _factory;
        createdAt = block.timestamp;
        tournamentName = _name;
        prizePool = _prizePool;
        status = Status.Registration;
    }
    
    // ========== REGISTRATION ==========
    
    /**
     * @dev Register player with World ID verification
     * @param _worldIdProof Proof of World ID verification (placeholder)
     */
    function register(bytes calldata _worldIdProof) external {
        require(!registered[msg.sender], "Already registered");
        require(status == Status.Registration, "Registration closed");
        require(_worldIdProof.length > 0, "Invalid World ID proof");
        
        // TODO: Verify World ID proof against World Chain oracle
        // This is a placeholder for World ID integration
        
        registered[msg.sender] = true;
        players.push(msg.sender);
        
        emit PlayerRegistered(msg.sender, block.timestamp);
    }
    
    /**
     * @dev Start tournament (factory only)
     */
    function startTournament() external onlyFactory {
        require(status == Status.Registration, "Already started");
        require(players.length >= 2, "Need at least 2 players");
        
        status = Status.Active;
        claimDeadline = block.timestamp + 30 days;
        
        emit TournamentStatusChanged(Status.Active);
    }
    
    // ========== SCORING ==========
    
    /**
     * @dev Submit score for a match
     * @param _matchId Match identifier
     * @param _result Match result (-1 loss, 0 draw, 1 win)
     */
    function submitScore(uint256 _matchId, int8 _result) external onlyRegistered onlyActive {
        require(_matchId < matchCount, "Invalid match");
        require(_result >= -1 && _result <= 1, "Invalid result");
        
        Match storage match_ = matches[_matchId];
        require(block.timestamp <= match_.submissionDeadline, "Submission window closed");
        require(msg.sender == match_.player1 || msg.sender == match_.player2, "Not a participant");
        
        if (msg.sender == match_.player1) {
            match_.score1 = _result;
        } else {
            match_.score2 = _result;
        }
        
        // Check if both players have submitted
        if (match_.score1 != 0 && match_.score2 != 0) {
            _resolveMatch(_matchId);
        }
        
        emit ScoreSubmitted(_matchId, msg.sender, _result);
    }
    
    /**
     * @dev Resolve match if scores agree or timeout elapsed
     */
    function _resolveMatch(uint256 _matchId) internal {
        Match storage match_ = matches[_matchId];
        
        if (match_.score1 == match_.score2) {
            match_.confirmed = true;
        } else if (block.timestamp > match_.submissionDeadline) {
            // Timeout: escalate to dispute
            _createDispute(_matchId);
        }
    }
    
    // ========== DISPUTE RESOLUTION ==========
    
    /**
     * @dev Create dispute for conflicting scores
     */
    function _createDispute(uint256 _matchId) internal {
        Match storage match_ = matches[_matchId];
        match_.disputed = true;
        
        DisputeData storage dispute = disputes[disputeCount];
        dispute.plaintiff = match_.player1;
        dispute.defendant = match_.player2;
        dispute.matchId = _matchId;
        dispute.deadline = block.timestamp + disputeWindow;
        dispute.resolved = false;
        
        status = Status.Disputed;
        
        emit DisputeEscalated(disputeCount, _matchId);
        disputeCount++;
    }
    
    /**
     * @dev Escalate to arbitration (placeholder for jury/stake mechanism)
     */
    function escalateDispute(uint256 _disputeId) external onlyRegistered {
        require(_disputeId < disputeCount, "Invalid dispute");
        DisputeData storage dispute = disputes[_disputeId];
        require(!dispute.resolved, "Already resolved");
        
        // TODO: Implement stake-based or jury-based resolution
        // This is a placeholder for arbitration integration
    }
    
    // ========== PRIZE DISTRIBUTION ==========
    
    /**
     * @dev Distribute prize to winner
     * @param _player Winner address
     * @param _amount Prize amount
     */
    function distributePrize(address _player, uint256 _amount) external onlyFactory nonReentrant {
        require(_amount <= prizePool, "Insufficient pool");
        require(block.timestamp <= claimDeadline, "Claim deadline passed");
        
        prizePool -= _amount;
        prizes[_player] += _amount;
        
        emit PrizeDistributed(_player, _amount);
    }
    
    /**
     * @dev Claim prize (player initiated)
     */
    function claimPrize() external nonReentrant {
        uint256 amount = prizes[msg.sender];
        require(amount > 0, "No prize to claim");
        require(status == Status.Complete, "Tournament not complete");
        
        prizes[msg.sender] = 0;
        
        (bool success, ) = payable(msg.sender).call{value: amount}("");
        require(success, "Transfer failed");
    }
    
    // ========== VIEW FUNCTIONS ==========
    
    function getPlayerCount() external view returns (uint256) {
        return players.length;
    }
    
    function getPlayers() external view returns (address[] memory) {
        return players;
    }
    
    function getMatch(uint256 _matchId) external view returns (Match memory) {
        require(_matchId < matchCount, "Invalid match");
        return matches[_matchId];
    }
    
    function getDispute(uint256 _disputeId) external view returns (DisputeData memory) {
        require(_disputeId < disputeCount, "Invalid dispute");
        return disputes[_disputeId];
    }
    
    // ========== ADMIN FUNCTIONS ==========
    
    function completeTournament() external onlyFactory {
        status = Status.Complete;
        emit TournamentStatusChanged(Status.Complete);
    }
    
    function pause() external onlyOwner {
        _pause();
    }
    
    function unpause() external onlyOwner {
        _unpause();
    }
    
    // Receive ETH
    receive() external payable {}
}
