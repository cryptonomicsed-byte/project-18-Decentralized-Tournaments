// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/**
 * @title WorldIDVerifier
 * @dev Interface for World ID verification
 * @notice Placeholder for World Chain native World ID integration
 */

library WorldIDVerifier {
    
    // ========== STRUCTURES ==========
    
    struct WorldIDProof {
        uint256[] proof;
        uint256 root;
        uint256 nullifierHash;
        uint256 signal;
    }
    
    // ========== STATE ==========
    
    mapping(address => bool) private verified;
    mapping(address => uint256) private verificationTime;
    
    // ========== EVENTS ==========
    
    event WorldIDVerified(address indexed user, uint256 timestamp);
    event WorldIDRevoked(address indexed user);
    
    // ========== FUNCTIONS ==========
    
    /**
     * @dev Verify World ID proof
     * @param _proof Proof struct (will be validated against World Chain contract)
     * @param _user User address to verify
     * @notice On World Chain mainnet, this integrates with native World ID
     */
    function verifyProof(
        WorldIDProof calldata _proof,
        address _user
    ) internal {
        require(_user != address(0), "Invalid address");
        
        // TODO: On World Chain, validate against:
        // https://docs.world.org/world-id/integration-guide
        // For testnet: accept proof if non-empty
        require(_proof.proof.length > 0, "Invalid proof");
        require(_proof.nullifierHash != 0, "Invalid nullifier");
        
        // Mark as verified
        verified[_user] = true;
        verificationTime[_user] = block.timestamp;
        
        emit WorldIDVerified(_user, block.timestamp);
    }
    
    /**
     * @dev Check if address is World ID verified
     */
    function isVerified(address _user) internal view returns (bool) {
        return verified[_user];
    }
    
    /**
     * @dev Get verification timestamp
     */
    function getVerificationTime(address _user) internal view returns (uint256) {
        return verificationTime[_user];
    }
    
    /**
     * @dev Revoke verification (for testing/recovery)
     */
    function revokeVerification(address _user) internal {
        require(verified[_user], "Not verified");
        verified[_user] = false;
        emit WorldIDRevoked(_user);
    }
}
