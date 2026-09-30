// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/**
 * @title ArbitrationTest
 * @dev Test harness for Arbitration library with full jury voting
 * @notice Implements stake-weighted jury selection and vote tally
 */

import "../libraries/Arbitration.sol";

contract ArbitrationTest {
    using Arbitration for Arbitration.DisputeSession;
    
    // ========== STATE ==========
    
    mapping(uint256 => Arbitration.DisputeSession) public disputes;
    uint256 public disputeCounter;
    
    // Jury management
    mapping(uint256 => mapping(address => bool)) public isJuror;
    mapping(uint256 => mapping(address => uint256)) public jurorStakes;
    mapping(uint256 => address[]) public juryPool;
    mapping(uint256 => uint256) public voteDeadline;
    
    // Jury voting
    struct JuryVote {
        address juror;
        uint256 stake;
        bool votedForPlaintiff;
        uint256 timestamp;
    }
    mapping(uint256 => JuryVote[]) public votes;
    mapping(uint256 => bool) public votesTallied;
    mapping(uint256 => address) public verdictWinner;
    
    // ========== EVENTS ==========
    
    event DisputeCreated(uint256 indexed id, address plaintiff, address defendant);
    event JurorSelected(uint256 indexed disputeId, address indexed juror);
    event VoteSubmitted(uint256 indexed disputeId, address indexed juror, bool forPlaintiff);
    event VotesTallied(uint256 indexed disputeId, address winner);
    event DisputeResolved(uint256 indexed disputeId, address winner);
    
    // ========== TEST HELPERS ==========
    
    /**
     * @dev Create dispute for testing
     */
    function createTestDispute(
        address _plaintiff,
        address _defendant,
        uint256 _matchId
    ) external returns (uint256) {
        uint256 disputeId = disputeCounter++;
        
        Arbitration.DisputeSession storage dispute = disputes[disputeId];
        dispute.createDispute(_plaintiff, _defendant, _matchId);
        
        emit DisputeCreated(disputeId, _plaintiff, _defendant);
        return disputeId;
    }
    
    /**
     * @dev Submit evidence for testing
     */
    function submitTestEvidence(uint256 _disputeId, bytes calldata _evidence) external {
        require(_disputeId < disputeCounter, "Invalid dispute");
        disputes[_disputeId].submitEvidence(msg.sender, _evidence);
    }
    
    /**
     * @dev Submit stake for testing
     */
    function submitTestStake(uint256 _disputeId, uint256 _amount) external {
        require(_disputeId < disputeCounter, "Invalid dispute");
        disputes[_disputeId].submitStake(msg.sender, _amount);
    }
    
    /**
     * @dev Resolve timeout for testing
     */
    function resolveTestTimeout(uint256 _disputeId) external {
        require(_disputeId < disputeCounter, "Invalid dispute");
        disputes[_disputeId].resolveTimeout();
    }
    
    /**
     * @dev Get dispute for testing
     */
    function getTestDispute(uint256 _disputeId) external view returns (
        address plaintiff,
        address defendant,
        uint256 matchId,
        Arbitration.DisputeStatus status,
        bool resolved,
        address winner
    ) {
        Arbitration.DisputeSession storage d = disputes[_disputeId];
        return (
            d.plaintiff,
            d.defendant,
            d.matchId,
            d.status,
            d.resolved,
            d.winner
        );
    }
    
    /**
     * @dev Get evidence count for testing
     */
    function getEvidenceCount(uint256 _disputeId) external view returns (uint256) {
        return disputes[_disputeId].evidenceCount;
    }
    
    // ========== JURY VOTING ==========
    
    /**
     * @dev Select jury pool (simplified: first N registered stakers)
     * @param _disputeId Dispute identifier
     * @param _jurors Array of juror addresses
     * @param _stakes Array of juror stakes
     */
    function selectJury(
        uint256 _disputeId,
        address[] calldata _jurors,
        uint256[] calldata _stakes
    ) external {
        require(_disputeId < disputeCounter, "Invalid dispute");
        require(_jurors.length == _stakes.length, "Mismatched arrays");
        require(_jurors.length >= 3, "Need at least 3 jurors");
        require(_jurors.length <= 12, "Too many jurors");
        
        Arbitration.DisputeSession storage dispute = disputes[_disputeId];
        require(dispute.status == Arbitration.DisputeStatus.JuryVoting, "Not in jury phase");
        
        // Register jurors
        for (uint256 i = 0; i < _jurors.length; i++) {
            require(_jurors[i] != address(0), "Invalid juror");
            require(_stakes[i] >= 0.1 ether, "Stake too low");
            require(!isJuror[_disputeId][_jurors[i]], "Duplicate juror");
            
            isJuror[_disputeId][_jurors[i]] = true;
            jurorStakes[_disputeId][_jurors[i]] = _stakes[i];
            juryPool[_disputeId].push(_jurors[i]);
            
            emit JurorSelected(_disputeId, _jurors[i]);
        }
        
        voteDeadline[_disputeId] = block.timestamp + 48 hours;
    }
    
    /**
     * @dev Submit jury vote (stake-weighted)
     * @param _disputeId Dispute identifier
     * @param _voteForPlaintiff true = vote plaintiff, false = vote defendant
     */
    function submitVote(uint256 _disputeId, bool _voteForPlaintiff) external {
        require(_disputeId < disputeCounter, "Invalid dispute");
        require(isJuror[_disputeId][msg.sender], "Not selected as juror");
        require(block.timestamp < voteDeadline[_disputeId], "Voting expired");
        require(!votesTallied[_disputeId], "Votes already tallied");
        
        uint256 stake = jurorStakes[_disputeId][msg.sender];
        require(stake > 0, "Invalid stake");
        
        votes[_disputeId].push(JuryVote({
            juror: msg.sender,
            stake: stake,
            votedForPlaintiff: _voteForPlaintiff,
            timestamp: block.timestamp
        }));
        
        emit VoteSubmitted(_disputeId, msg.sender, _voteForPlaintiff);
    }
    
    /**
     * @dev Tally jury votes (stake-weighted)
     * @param _disputeId Dispute identifier
     * @return winner Address of winner based on vote tally
     */
    function tallyVotes(uint256 _disputeId) external returns (address) {
        require(_disputeId < disputeCounter, "Invalid dispute");
        require(!votesTallied[_disputeId], "Already tallied");
        require(block.timestamp >= voteDeadline[_disputeId], "Voting not closed");
        
        JuryVote[] storage voteList = votes[_disputeId];
        require(voteList.length > 0, "No votes submitted");
        
        uint256 plaintiffWeight = 0;
        uint256 defendantWeight = 0;
        
        // Calculate weighted vote totals
        for (uint256 i = 0; i < voteList.length; i++) {
            if (voteList[i].votedForPlaintiff) {
                plaintiffWeight += voteList[i].stake;
            } else {
                defendantWeight += voteList[i].stake;
            }
        }
        
        // Determine winner
        Arbitration.DisputeSession storage dispute = disputes[_disputeId];
        if (plaintiffWeight > defendantWeight) {
            dispute.winner = dispute.plaintiff;
        } else if (defendantWeight > plaintiffWeight) {
            dispute.winner = dispute.defendant;
        } else {
            // Tie: plaintiff wins by default (burden on defendant)
            dispute.winner = dispute.plaintiff;
        }
        
        votesTallied[_disputeId] = true;
        verdictWinner[_disputeId] = dispute.winner;
        dispute.resolved = true;
        dispute.status = Arbitration.DisputeStatus.Resolved;
        
        emit VotesTallied(_disputeId, dispute.winner);
        emit DisputeResolved(_disputeId, dispute.winner);
        
        return dispute.winner;
    }
    
    /**
     * @dev Check if juror vote matches expected outcome (for collusion detection)
     * @param _disputeId Dispute identifier
     * @param _juror Juror address
     * @return votedForPlaintiff How the juror voted
     */
    function getJurorVote(uint256 _disputeId, address _juror) external view returns (bool) {
        JuryVote[] storage voteList = votes[_disputeId];
        for (uint256 i = 0; i < voteList.length; i++) {
            if (voteList[i].juror == _juror) {
                return voteList[i].votedForPlaintiff;
            }
        }
        revert("Juror vote not found");
    }
    
    /**
     * @dev Get jury statistics (for analysis)
     */
    function getJuryStats(uint256 _disputeId) external view returns (
        uint256 totalJurors,
        uint256 votesReceived,
        uint256 plaintiffWeight,
        uint256 defendantWeight
    ) {
        totalJurors = juryPool[_disputeId].length;
        votesReceived = votes[_disputeId].length;
        
        JuryVote[] storage voteList = votes[_disputeId];
        for (uint256 i = 0; i < voteList.length; i++) {
            if (voteList[i].votedForPlaintiff) {
                plaintiffWeight += voteList[i].stake;
            } else {
                defendantWeight += voteList[i].stake;
            }
        }
    }
    
    /**
     * @dev Check vote participation rate
     */
    function getParticipationRate(uint256 _disputeId) external view returns (uint256) {
        uint256 total = juryPool[_disputeId].length;
        if (total == 0) return 0;
        return (votes[_disputeId].length * 100) / total;
    }
    
    // ========== VIEW FUNCTIONS ==========
    
    function getDisputeCount() external view returns (uint256) {
        return disputeCounter;
    }
    
    function getJuryPoolSize(uint256 _disputeId) external view returns (uint256) {
        return juryPool[_disputeId].length;
    }
    
    function getVoteCount(uint256 _disputeId) external view returns (uint256) {
        return votes[_disputeId].length;
    }
    
    function isDisputeResolved(uint256 _disputeId) external view returns (bool) {
        require(_disputeId < disputeCounter, "Invalid dispute");
        return disputes[_disputeId].resolved;
    }
    
    function getDisputeWinner(uint256 _disputeId) external view returns (address) {
        require(_disputeId < disputeCounter, "Invalid dispute");
        return disputes[_disputeId].winner;
    }
}
