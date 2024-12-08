// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract ReputationManager {
    mapping(address => uint256) public reputationScore;

    function updateReputation(address _creator, bool _successful) external {
        if (_successful) {
            reputationScore[_creator] += 10;
        } else {
            reputationScore[_creator] -= 5;
        }
    }

    function getReputation(address _creator) external view returns (uint256) {
        return reputationScore[_creator];
    }
}

