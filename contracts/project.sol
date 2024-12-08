// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./Funding.sol";
import "./Rewards.sol";
import "./Governance.sol";
import "./ReputationManager.sol";

contract Project is ReentrancyGuard {
    enum ProjectState { Ongoing, Completed, Cancelled }

    address public creator;
    Funding public funding;
    Rewards public rewards;
    Governance public governance;
    ReputationManager public reputationManager;

    string public projectName;
    string public projectDescription;
    uint256 public totalFundsGoal;
    uint256 public totalRaised;
    ProjectState public state;
    IERC20 public investmentToken;

    uint256 public totalMilestones;
    mapping(uint256 => Funding.Milestone) public milestones;
    mapping(address => uint256) public contributions;

    event ProjectFunded(address indexed backer, uint256 amount, uint256 milestoneId);
    event MilestoneCompleted(uint256 milestoneId);
    event RewardsDistributed(address indexed backer, uint256 amount);
    event ProjectCompleted(address indexed creator);
    event ProjectCancelled(address indexed creator);

    modifier onlyCreator() {
        require(msg.sender == creator, "Only the project creator can call this");
        _;
    }

    modifier projectOngoing() {
        require(state == ProjectState.Ongoing, "Project is not ongoing");
        _;
    }

    constructor(
        address _creator,
        address _investmentToken,
        uint256 _totalFundsGoal,
        address _funding,
        address _rewards,
        address _governance,
        address _reputationManager
    ) {
        creator = _creator;
        investmentToken = IERC20(_investmentToken);
        totalFundsGoal = _totalFundsGoal;
        funding = Funding(_funding);
        rewards = Rewards(_rewards);
        governance = Governance(_governance);
        reputationManager = ReputationManager(_reputationManager);
        state = ProjectState.Ongoing;
    }

    // Contribute funds to a specific milestone
    function contribute(uint256 _milestoneId, uint256 _amount) external nonReentrant projectOngoing {
        require(_milestoneId < totalMilestones, "Invalid milestone");
        require(totalRaised + _amount <= totalFundsGoal, "Total funds raised exceeded goal");

        investmentToken.transferFrom(msg.sender, address(this), _amount);
        contributions[msg.sender] += _amount;

        milestones[_milestoneId].amountRaised += _amount;
        totalRaised += _amount;

        emit ProjectFunded(msg.sender, _amount, _milestoneId);
    }

    // Add a new milestone to the project
    function addMilestone(string memory _description, uint256 _targetAmount) external onlyCreator projectOngoing {
        funding.addMilestone(_description, _targetAmount);
        totalMilestones++;
    }

    // Complete the project and mark it as finished
    function completeProject() external onlyCreator {
        state = ProjectState.Completed;
        emit ProjectCompleted(creator);
    }

    // Cancel the project if needed
    function cancelProject() external onlyCreator {
        state = ProjectState.Cancelled;
        emit ProjectCancelled(creator);
    }

    // Release funds for a completed milestone (via Funding contract)
    function releaseFunds(uint256 _milestoneId) external onlyCreator projectOngoing {
        funding.releaseFunds(_milestoneId);
        emit MilestoneCompleted(_milestoneId);
    }

    // Issue refunds for a failed milestone (via Funding contract)
    function issueRefunds(uint256 _milestoneId) external onlyCreator projectOngoing {
        funding.issueRefunds(_milestoneId);
    }

    // Distribute rewards to backers for a specific milestone
    function distributeRewards(address _backer, uint256 _amount) external onlyCreator projectOngoing {
        // rewards.distribute(_backer, _amount);
        emit RewardsDistributed(_backer, _amount);
    }

    // Function to withdraw remaining funds (in case of project cancellation)
    function withdrawRemainingFunds() external onlyCreator projectOngoing {
        uint256 remainingFunds = investmentToken.balanceOf(address(this));
        require(remainingFunds > 0, "No funds available for withdrawal");

        investmentToken.transfer(creator, remainingFunds);
    }
}

