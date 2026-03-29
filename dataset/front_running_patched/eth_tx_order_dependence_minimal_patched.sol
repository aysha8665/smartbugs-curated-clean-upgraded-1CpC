// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract EthTxOrderDependenceMinimalFixed {
    address public owner;
    bool public claimed;
    uint public reward;

    // --- Commit-Reveal State ---
    struct Commit {
        bytes32 solutionHash;
        uint256 commitBlock;
    }
    // Maps a user's address to their hidden commitment
    mapping(address => Commit) public commits;

    constructor() payable {
        owner = msg.sender;
        reward = msg.value; // Initialize the reward if ether is sent during deployment
    }

    function setReward() public payable {
        require(!claimed, "Reward already claimed");
        require(msg.sender == owner, "Only owner can set reward");
        
        uint oldReward = reward;
        reward = msg.value;
        
        // Transfer after state update (Checks-Effects-Interactions)
        payable(owner).transfer(oldReward);
    }

    /**
     * @dev STEP 1: COMMIT
     * The user submits a hidden hash of their solution and a secret password (salt).
     * Because it's hashed, mempool attackers cannot see the actual answer.
     * To generate the hash off-chain: keccak256(abi.encodePacked(userAddress, submission, secretSalt))
     */
    function commitSolution(bytes32 _solutionHash) public {
        require(!claimed, "Reward already claimed");
        commits[msg.sender] = Commit({
            solutionHash: _solutionHash,
            commitBlock: block.number
        });
    }

    /**
     * @dev STEP 2: REVEAL
     * After waiting at least 1 block, the user reveals their answer.
     * Attackers cannot front-run this because the hash is cryptographically tied to the user's address.
     */
    function claimReward(uint256 submission, string memory secretSalt, uint256 expectedReward) public {
        require(!claimed, "Reward already claimed");
        require(submission < 10, "Invalid submission");
        
        // 1. Slippage Check: Protects against the "Owner Rug-Pull" front-run
        require(reward == expectedReward, "Reward amount has changed");

        // 2. Commit Check: Ensure the user actually committed previously
        Commit memory userCommit = commits[msg.sender];
        require(userCommit.commitBlock != 0, "No commit found for this address");
        
        // 3. Delay Check: Prevents an attacker from committing and revealing in the exact same block
        require(block.number > userCommit.commitBlock, "Must wait at least 1 block after commit");

        // 4. Cryptographic Verification: Reconstruct the hash to prove ownership of the solution
        bytes32 expectedHash = keccak256(abi.encodePacked(msg.sender, submission, secretSalt));
        require(userCommit.solutionHash == expectedHash, "Invalid solution or salt");
        
        // 5. Payout (Checks-Effects-Interactions pattern)
        claimed = true;
        
        // Use .call instead of .transfer to prevent gas griefing, checking success
        (bool success, ) = msg.sender.call{value: reward}("");
        require(success, "Transfer failed");
    }
}