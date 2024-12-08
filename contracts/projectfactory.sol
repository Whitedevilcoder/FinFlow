// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Project.sol";

contract ProjectFactory {
    string public projectDescription;

    struct ProjectInfo {
        address projectAddress;
        address creator;
        string projectName;
        string projectDescription;
        uint256 totalFundsGoal;
        bool isProfit;
    }

    ProjectInfo[] public projects; // Array of deployed projects

    event ProjectCreated(
        address indexed projectAddress,
        address indexed creator,
        string projectName,
        uint256 totalFundsGoal,
        bool isProfit
    );

    function createProject(
        string memory _projectName,
        string memory _projectDescription,
        uint256 _totalFundsGoal,
        address _paymentToken,
        bool _isProfit,
        address _funding,
        address _rewards,
        address _governance,
        address _reputationManager
    ) external {
        require(bytes(_projectName).length > 0, "Project name is required");
        require(bytes(_projectDescription).length > 0, "Project description is required");
        require(_totalFundsGoal > 0, "Funding goal must be greater than zero");
        require(_paymentToken != address(0), "Invalid payment token");

        // Deploy a new Project contract with all necessary parameters
        Project newProject = new Project(
            msg.sender,          // _creator
            _paymentToken,       // _investmentToken
            _totalFundsGoal,     // _totalFundsGoal
            _funding,            // _funding
            _rewards,            // _rewards
            _governance,         // _governance
            _reputationManager   // _reputationManager
        );

        projects.push(
            ProjectInfo({
                projectAddress: address(newProject),
                creator: msg.sender,
                projectName: _projectName,
                projectDescription: _projectDescription,
                totalFundsGoal: _totalFundsGoal,
                isProfit: _isProfit
            })
        );

        emit ProjectCreated(address(newProject), msg.sender, _projectName, _totalFundsGoal, _isProfit);
    }

    function contributeToProject(uint256 _projectIndex, uint256 _milestoneId, uint256 _amount) external {
        require(_projectIndex < projects.length, "Invalid project index");

        Project targetProject = Project(projects[_projectIndex].projectAddress);
        targetProject.contribute(_milestoneId, _amount);
    }

    // function getMilestoneDetails(uint256 _projectIndex, uint256 _milestoneId)
    //     external
    //     view
    //     returns (
    //         string memory description,
    //         uint256 targetAmount,
    //         uint256 amountRaised,
    //         bool completed
    //     )
    // {
    //     require(_projectIndex < projects.length, "Invalid project index");
    //     Project targetProject = Project(projects[_projectIndex].projectAddress);
    //     return targetProject.getMilestone(_milestoneId);
    // }


    function getProjectsCount() external view returns (uint256) {
        return projects.length;
    }

    function getProjectInfo(uint256 _index)
        external
        view
        returns (
            address projectAddress,
            address creator,
            string memory projectName,
            string memory projectDescription,
            uint256 totalFundsGoal,
            bool isProfit
        )
    {
        require(_index < projects.length, "Invalid project index");
        ProjectInfo memory info = projects[_index];
        return (
            info.projectAddress,
            info.creator,
            info.projectName,
            info.projectDescription,
            info.totalFundsGoal,
            info.isProfit
        );
    }
}

