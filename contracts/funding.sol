// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract Funding is ReentrancyGuard {
    enum FundReleaseState { Pending, Released, Refunded }

    struct Investment {
        address investor;
        uint256 amount;
        uint256 milestoneId;
    }

    struct Milestone {
        string description;
        uint256 targetAmount;
        uint256 amountRaised;
        uint256 releaseThreshold;
        FundReleaseState releaseState;
    }

    // Token used for investments (could be MATIC or any ERC-20 token)
    IERC20 public investmentToken;

    address public projectCreator;
    uint256 public totalGoal;
    uint256 public totalRaised;

    uint256 public totalMilestones;
    mapping(uint256 => Milestone) public milestones;
    mapping(address => Investment[]) public investments; // Track investments by address

    event FundReceived(address indexed backer, uint256 amount, uint256 milestoneId);
    event MilestoneFundReleased(uint256 milestoneId, uint256 amount);
    event RefundIssued(address indexed backer, uint256 amount);
    event FundReleased(address indexed backer, uint256 amount);

    modifier onlyCreator() {
        require(msg.sender == projectCreator, "Only the project creator can call this");
        _;
    }

    modifier milestoneMet(uint256 milestoneId) {
        require(milestones[milestoneId].amountRaised >= milestones[milestoneId].targetAmount, "Milestone target not met");
        _;
    }

    modifier milestoneNotMet(uint256 milestoneId) {
        require(milestones[milestoneId].amountRaised < milestones[milestoneId].targetAmount, "Milestone target met");
        _;
    }

    constructor(address _investmentToken, address _projectCreator, uint256 _totalGoal) {
        investmentToken = IERC20(_investmentToken);
        projectCreator = _projectCreator;
        totalGoal = _totalGoal;
    }

    // Function to invest in the project (invest in a specific milestone)
    function invest(uint256 _milestoneId, uint256 _amount) external nonReentrant {
        require(_milestoneId < totalMilestones, "Invalid milestone");

        // Ensure the project has not surpassed the total goal
        require(totalRaised + _amount <= totalGoal, "Total funds raised exceeded goal");

        // Transfer tokens from backer to contract
        investmentToken.transferFrom(msg.sender, address(this), _amount);

        // Record the investment
        investments[msg.sender].push(Investment({
            investor: msg.sender,
            amount: _amount,
            milestoneId: _milestoneId
        }));

        // Update milestone amount raised
        milestones[_milestoneId].amountRaised += _amount;

        // Update total raised
        totalRaised += _amount;

        emit FundReceived(msg.sender, _amount, _milestoneId);
    }

    // Function to release funds for a completed milestone
    function releaseFunds(uint256 _milestoneId) external nonReentrant onlyCreator milestoneMet(_milestoneId) {
        Milestone storage milestone = milestones[_milestoneId];

        require(milestone.releaseState == FundReleaseState.Pending, "Funds already released for this milestone");
        uint256 amountToRelease = milestone.amountRaised;
        require(amountToRelease > 0, "No funds available for release");

        // Change milestone state to released
        milestone.releaseState = FundReleaseState.Released;

        // Transfer funds to the project creator
        investmentToken.transfer(projectCreator, amountToRelease);

        emit MilestoneFundReleased(_milestoneId, amountToRelease);
    }

    // Function to issue refunds for a failed milestone (if milestone is not met)
    function issueRefunds(uint256 _milestoneId) external nonReentrant milestoneNotMet(_milestoneId) {
        Milestone storage milestone = milestones[_milestoneId];

        // Refund all investors in the milestone
        for (uint256 i = 0; i < investments[msg.sender].length; i++) {
            Investment memory investment = investments[msg.sender][i];
            if (investment.milestoneId == _milestoneId) {
                uint256 refundAmount = investment.amount;
                require(investmentToken.balanceOf(address(this)) >= refundAmount, "Insufficient funds for refund");

                // Transfer refund to backer
                investmentToken.transfer(investment.investor, refundAmount);

                emit RefundIssued(investment.investor, refundAmount);
            }
        }

        // Update milestone state to refunded
        milestone.releaseState = FundReleaseState.Refunded;
    }

    // Function to withdraw remaining funds (in case the project is cancelled)
    function withdrawRemainingFunds() external onlyCreator {
        uint256 remainingFunds = investmentToken.balanceOf(address(this));
        require(remainingFunds > 0, "No funds available for withdrawal");

        investmentToken.transfer(projectCreator, remainingFunds);
    }

    // Function to add a new milestone
    function addMilestone(string memory _description, uint256 _targetAmount) external onlyCreator {
        milestones[totalMilestones] = Milestone({
            description: _description,
            targetAmount: _targetAmount,
            amountRaised: 0,
            releaseThreshold: 0,
            releaseState: FundReleaseState.Pending
        });
        totalMilestones++;
    }
}

