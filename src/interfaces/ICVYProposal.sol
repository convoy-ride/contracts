pragma solidity ^0.8.0;

import {IERC20} from '@openzeppelin/contracts/token/ERC20/IERC20.sol';

enum ProposalState {
    Pending,
    Active,
    Canceled,
    Defeated,
    Succeeded
}

enum VoteType {
    Against,
    For,
    Abstain
}

interface ICVYProposal {
    // === Error definitions === //
    error AlreadyInitialized();

    // === View Functions ===//
    function factory() external view returns (address);
    function currentState() external view returns (ProposalState);
    function start() external view returns (uint256);
    function end() external view returns (uint256);
    function assent() external view returns (uint256);
    function dissent() external view returns (uint256);
    function abstainment() external view returns (uint256);
    function description() external view returns (string memory);
    function callData(uint256 index) external view returns (bytes memory);
    function quorum() external view returns (uint256);
    function title() external view returns (string memory);

    // === State Changing Functions ===//

    function initialize(
        address initiator,
        string memory title,
        string memory description,
        uint256 duration,
        uint256 quorum,
        bytes[] memory callData
    ) external;
    function castVote(VoteType voteType) external;
    function execute() external;
}
