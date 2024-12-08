// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Governance {
    struct Proposal {
        uint256 id;
        string description;
        uint256 votesFor;
        uint256 votesAgainst;
        uint256 totalVotes;
        bool executed;
        address proposer;
    }

    uint256 public quorum;
    uint256 public proposalCount;
    mapping(uint256 => Proposal) public proposals;
    mapping(address => uint256) public votingPower;

    function createProposal(string memory _description) external {
        proposalCount++;
        proposals[proposalCount] = Proposal({
            id: proposalCount,
            description: _description,
            votesFor: 0,
            votesAgainst: 0,
            totalVotes: 0,
            executed: false,
            proposer: msg.sender
        });
    }

    function vote(uint256 _proposalId, bool _support) external {
        Proposal storage proposal = proposals[_proposalId];
        require(!proposal.executed, "Proposal already executed");
        uint256 power = votingPower[msg.sender];

        if (_support) {
            proposal.votesFor += power;
        } else {
            proposal.votesAgainst += power;
        }
        proposal.totalVotes += power;
    }

    function executeProposal(uint256 _proposalId) external {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.totalVotes >= quorum, "Quorum not met");
        require(proposal.votesFor > proposal.votesAgainst, "Proposal not approved");
        proposal.executed = true;
    }
}

