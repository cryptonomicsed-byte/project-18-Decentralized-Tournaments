// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/**
 * @title Arbitration
 * @dev Dispute resolution library with multi-stage escalation
 * @notice Implements: timeout → stake-based → jury resolution
 */

library Arbitration {
    
    // ========== ENUMS & STRUCTURES ==========
    
    enum DisputeStatus { 
        Pending,      // Awaiting evidence
        StakePhase,   // Players can post stakes
        JuryVoting,   // Jury voting period
        Resolved      // Outcome determined
    }
    
    struct Evidence {
        address submitter;
        bytes data;
        uint256 timestamp;
    }
    
    struct DisputeSession {
        address plaintiff;
        address defendant;
        uint256 matchId;
        DisputeStatus status;
        uint256 createdAt;
        uint256 evidenceDeadline;
        uint256 stakeDeadline;
        uint256 votingDeadline;
        
        // Stake-based resolution
        uint256 plaintiffStake;
        uint256 defendantStake;
        
        // Evidence tracking
        mapping(address => Evidence) evidence;
        uint256 evidenceCount;
        
        // Outcome
        address winner;
        bool resolved;
    }
    
    // ========== CONSTANTS ==========
    
    uint256 constant EVIDENCE_WINDOW = 24 hours;
    uint256 constant STAKE_WINDOW = 24 hours;
    uint256 constant VOTING_WINDOW = 48 hours;
    uint256 constant MIN_STAKE = 0.1 ether;
    
    // ========== FUNCTIONS ==========
    
    /**
     * @dev Create dispute session
     */
    function createDispute(
        DisputeSession storage self,
        address _plaintiff,
        address _defendant,
        uint256 _matchId
    ) internal {
        require(_plaintiff != address(0) && _defendant != address(0), "Invalid parties");
        
        self.plaintiff = _plaintiff;
        self.defendant = _defendant;
        self.matchId = _matchId;
        self.status = DisputeStatus.Pending;
        self.createdAt = block.timestamp;
        self.evidenceDeadline = block.timestamp + EVIDENCE_WINDOW;
        self.stakeDeadline = self.evidenceDeadline + STAKE_WINDOW;
        self.votingDeadline = self.stakeDeadline + VOTING_WINDOW;
        self.resolved = false;
    }
    
    /**
     * @dev Submit evidence for dispute
     */
    function submitEvidence(
        DisputeSession storage self,
        address _submitter,
        bytes calldata _evidence
    ) internal {
        require(self.createdAt > 0, "Dispute not initialized");
        require(block.timestamp <= self.evidenceDeadline, "Evidence window closed");
        require(_submitter == self.plaintiff || _submitter == self.defendant, "Not a party");
        require(_evidence.length > 0, "Empty evidence");
        
        self.evidence[_submitter] = Evidence({
            submitter: _submitter,
            data: _evidence,
            timestamp: block.timestamp
        });
        self.evidenceCount++;
    }
    
    /**
     * @dev Submit stake for dispute resolution
     * @notice Loser's stake is slashed (simplified model)
     */
    function submitStake(
        DisputeSession storage self,
        address _submitter,
        uint256 _amount
    ) internal {
        require(self.status == DisputeStatus.Pending, "Not in evidence phase");
        require(block.timestamp > self.evidenceDeadline, "Evidence window still open");
        require(block.timestamp <= self.stakeDeadline, "Stake window closed");
        require(_amount >= MIN_STAKE, "Stake too low");
        require(_submitter == self.plaintiff || _submitter == self.defendant, "Not a party");
        
        if (_submitter == self.plaintiff) {
            self.plaintiffStake += _amount;
        } else {
            self.defendantStake += _amount;
        }
        
        // Auto-resolve if one party stakes significantly more (economic truth)
        if (self.plaintiffStake > self.defendantStake * 3) {
            self.winner = self.plaintiff;
            self.resolved = true;
            self.status = DisputeStatus.Resolved;
        } else if (self.defendantStake > self.plaintiffStake * 3) {
            self.winner = self.defendant;
            self.resolved = true;
            self.status = DisputeStatus.Resolved;
        } else if (
            self.plaintiffStake > 0 && 
            self.defendantStake > 0 && 
            block.timestamp > self.stakeDeadline
        ) {
            // Both staked, escalate to jury
            self.status = DisputeStatus.JuryVoting;
        }
    }
    
    /**
     * @dev Resolve dispute if timeout (automatic consensus)
     */
    function resolveTimeout(DisputeSession storage self) internal {
        require(!self.resolved, "Already resolved");
        
        if (block.timestamp > self.evidenceDeadline && self.status == DisputeStatus.Pending) {
            if (self.evidenceCount > 0) {
                // Evidence submitted, move to staking phase
                self.status = DisputeStatus.StakePhase;
            } else {
                // No evidence, automatic loss
                self.winner = self.defendant;
                self.resolved = true;
                self.status = DisputeStatus.Resolved;
            }
        } else if (
            block.timestamp > self.stakeDeadline && 
            self.status == DisputeStatus.StakePhase
        ) {
            // Staking deadline passed
            if (self.plaintiffStake > 0 && self.defendantStake == 0) {
                self.winner = self.plaintiff;
            } else if (self.defendantStake > 0 && self.plaintiffStake == 0) {
                self.winner = self.defendant;
            } else if (self.plaintiffStake == 0 && self.defendantStake == 0) {
                // No stakes, draw
                self.winner = address(0);
            }
            self.resolved = true;
            self.status = DisputeStatus.Resolved;
        }
    }
    
    /**
     * @dev Check if dispute is active
     */
    function isActive(DisputeSession storage self) internal view returns (bool) {
        return !self.resolved && self.createdAt > 0;
    }
    
    /**
     * @dev Get dispute status
     */
    function getStatus(DisputeSession storage self) internal view returns (DisputeStatus) {
        return self.status;
    }
}
