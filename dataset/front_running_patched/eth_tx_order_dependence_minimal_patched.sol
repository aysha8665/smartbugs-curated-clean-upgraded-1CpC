// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract EthTxOrderDependenceMinimalFixed {
    address public owner;
    bool public claimed;
    uint public reward;

    constructor() payable {
        owner = msg.sender;
        reward = msg.value; // Initialize the reward if ether is sent during deployment
    }

    function setReward() public payable {
        require(!claimed, "Reward already claimed");
        require(msg.sender == owner, "Only owner can set reward");
        
        uint oldReward = reward;
        reward = msg.value;
        
        // Transfer after state update
        payable(owner).transfer(oldReward);
    }

    // PATCH: Added 'expectedReward' parameter
    function claimReward(uint256 submission, uint256 expectedReward) public {
        require(!claimed, "Reward already claimed");
        require(submission < 10, "Invalid submission");
        
        // PATCH: Ensure the reward hasn't been maliciously changed
        require(reward == expectedReward, "Reward amount has changed");
        
        // PATCH: Checks-Effects-Interactions pattern (state update before transfer)
        claimed = true;
        payable(msg.sender).transfer(reward);
    }
}