// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/**
 * @title PrizeEscrow
 * @dev Safe prize pool management with clawback and timeout protection
 * @notice Handles unclaimed prizes, insufficient funds, and escrow safety
 */

library PrizeEscrow {
    
    // ========== STRUCTURES ==========
    
    struct EscrowAccount {
        uint256 balance;
        uint256 claimDeadline;
        bool withdrawn;
    }
    
    struct PoolMetadata {
        uint256 totalPool;
        uint256 distributed;
        uint256 unclaimed;
        uint256 clawbackDeadline;
        address poolOwner;
    }
    
    // ========== EVENTS ==========
    
    event PrizeDeposited(address indexed recipient, uint256 amount, uint256 deadline);
    event PrizeClaimed(address indexed recipient, uint256 amount);
    event PrizeClawed(address indexed recipient, uint256 amount, uint256 timestamp);
    event InsufficientFunds(uint256 requested, uint256 available);
    
    // ========== CONSTANTS ==========
    
    uint256 constant DEFAULT_CLAIM_PERIOD = 30 days;
    
    // ========== FUNCTIONS ==========
    
    /**
     * @dev Deposit prize for recipient
     */
    function depositPrize(
        mapping(address => EscrowAccount) storage accounts,
        address _recipient,
        uint256 _amount,
        uint256 _claimDeadline
    ) internal {
        require(_recipient != address(0), "Invalid recipient");
        require(_amount > 0, "Amount must be > 0");
        require(_claimDeadline > block.timestamp, "Deadline in past");
        
        accounts[_recipient].balance += _amount;
        accounts[_recipient].claimDeadline = _claimDeadline;
        
        emit PrizeDeposited(_recipient, _amount, _claimDeadline);
    }
    
    /**
     * @dev Claim prize if available
     */
    function claimPrize(
        mapping(address => EscrowAccount) storage accounts,
        address _claimer
    ) internal returns (uint256) {
        EscrowAccount storage account = accounts[_claimer];
        
        require(!account.withdrawn, "Already withdrawn");
        require(account.balance > 0, "No balance");
        require(block.timestamp <= account.claimDeadline, "Claim deadline passed");
        
        uint256 amount = account.balance;
        account.withdrawn = true;
        account.balance = 0;
        
        emit PrizeClaimed(_claimer, amount);
        return amount;
    }
    
    /**
     * @dev Clawback unclaimed prizes after deadline
     * @notice Only pool owner can clawback
     */
    function clawbackUnclaimed(
        mapping(address => EscrowAccount) storage accounts,
        address _claimant,
        address _poolOwner
    ) internal returns (uint256) {
        EscrowAccount storage account = accounts[_claimant];
        
        require(msg.sender == _poolOwner, "Not pool owner");
        require(account.balance > 0, "No balance");
        require(block.timestamp > account.claimDeadline, "Deadline not passed");
        require(!account.withdrawn, "Already withdrawn");
        
        uint256 amount = account.balance;
        account.balance = 0;
        account.withdrawn = true;
        
        emit PrizeClawed(_claimant, amount, block.timestamp);
        return amount;
    }
    
    /**
     * @dev Safe transfer with fallback for insufficient funds
     */
    function safeTransfer(
        uint256 _amount,
        uint256 _available
    ) internal pure returns (uint256) {
        if (_amount > _available) {
            emit InsufficientFunds(_amount, _available);
            return _available;
        }
        return _amount;
    }
    
    /**
     * @dev Get account balance
     */
    function getBalance(
        mapping(address => EscrowAccount) storage accounts,
        address _account
    ) internal view returns (uint256) {
        return accounts[_account].balance;
    }
    
    /**
     * @dev Check if claim deadline passed
     */
    function isClaimable(
        mapping(address => EscrowAccount) storage accounts,
        address _account
    ) internal view returns (bool) {
        EscrowAccount storage account = accounts[_account];
        return account.balance > 0 && 
               block.timestamp <= account.claimDeadline && 
               !account.withdrawn;
    }
    
    /**
     * @dev Get claim deadline for account
     */
    function getClaimDeadline(
        mapping(address => EscrowAccount) storage accounts,
        address _account
    ) internal view returns (uint256) {
        return accounts[_account].claimDeadline;
    }
}
