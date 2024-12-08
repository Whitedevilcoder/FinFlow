// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract Rewards {
    using SafeMath for uint256;
    enum RewardType { KarmaPoints }
    struct Reward {
        uint256 contributionThreshold; // Contribution required for the reward
        RewardType rewardType;
        string rewardDetails; // Could be token URI for NFTs or description for Karma Points
    }


    // Define backer structure
    struct Backer {
        uint256 contribution;  // Total contribution amount (in payment token)
        uint256 karmaPoints;   // Karma points accumulated
        uint256 tier;          // Tier based on contribution
    }

    enum Tier {Bronze, Silver, Gold}

    // State variables
    IERC20 public paymentToken;  // ERC-20 token (e.g., USDC, DAI) for contributions
    mapping(address => Backer) public backers;
    mapping(address => uint256) public contributions; // Backer address => total contribution
    Reward[] public rewards;
    uint256 public totalContributed;

    // Events
    event RewardDistributed(address indexed backer, string rewardDetails);
    event RewardIssued(address indexed backer, uint256 amount, uint256 karmaPoints, Tier tier);
    event KarmaPointsUpdated(address indexed backer, uint256 karmaPoints);

    // Constructor to set payment token and NFT contract
    constructor(address _paymentToken) {
        paymentToken = IERC20(_paymentToken);
    }

    // Function to handle contribution and update rewards
    function contribute(uint256 _amount) external {
        require(_amount > 0, "Contribution amount must be greater than zero");

        // Transfer the tokens from the backer to this contract
        require(paymentToken.transferFrom(msg.sender, address(this), _amount), "Token transfer failed");

        // Update the backer's contribution and karma points
        Backer storage backer = backers[msg.sender];
        backer.contribution = backer.contribution.add(_amount);
        totalContributed = totalContributed.add(_amount);

        // Calculate tier based on contribution
        backer.tier = getTier(backer.contribution);

        // Issue Karma Points (1 karma point per 100 tokens, adjust as needed)
        uint256 karmaPoints = _amount.div(100);
        backer.karmaPoints = backer.karmaPoints.add(karmaPoints);


        emit RewardIssued(msg.sender, _amount, karmaPoints, Tier(backer.tier));
        emit KarmaPointsUpdated(msg.sender, backer.karmaPoints);
    }

    function distributeRewards(address _backer, uint256 _amount) external  {
        uint256 backerContribution = contributions[_backer] + _amount;

        for (uint256 i = 0; i < rewards.length; i++) {
            if (backerContribution >= rewards[i].contributionThreshold) {
                emit RewardDistributed(_backer, rewards[i].rewardDetails);
                // Logic for distributing the reward (e.g., minting NFTs) would go here.
            }
        }
    }

    // Function to determine the tier based on contribution
    function getTier(uint256 _contribution) public pure returns (uint256) {
        if (_contribution >= 1000 ether) {  // Gold tier
            return uint256(Tier.Gold);
        } else if (_contribution >= 500 ether) {  // Silver tier
            return uint256(Tier.Silver);
        } else {  // Bronze tier
            return uint256(Tier.Bronze);
        }
    }

    // Function to get a backer's details
    function getBackerDetails(address _backer) external view returns (uint256 contribution, uint256 karmaPoints, uint256 tier) {
        Backer memory backer = backers[_backer];
        return (backer.contribution, backer.karmaPoints, backer.tier);
    }

    // Function to withdraw funds (for contract owner/admin only)
    function withdrawFunds(uint256 _amount) external {
        require(paymentToken.transfer(msg.sender, _amount), "Withdraw failed");
    }
}

