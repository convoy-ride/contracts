pragma solidity ^0.8.0;

import {
    ICVYProposal,
    ProposalState,
    VoteType
} from './interfaces/ICVYProposal.sol';
import {Ownable} from '@openzeppelin/contracts/access/Ownable.sol';

contract CVYProposal is ICVYProposal, Ownable {
    address public factory;
    ProposalState public currentState;
    uint256 public start;
    uint256 public end;
    uint256 public assent;
    uint256 public dissent;
    uint256 public abstainment;
    string public description;
    string public title;
    bytes[] public callData;
    uint256 public quorum;

    constructor() Ownable(msg.sender) {}

    function initialize(
        address initiator,
        string memory _title,
        string memory _description,
        uint256 _duration,
        uint256 _quorum,
        bytes[] memory _callData
    ) external {
        if (factory != address(0)) revert AlreadyInitialized();
        factory = msg.sender;
        _transferOwnership(initiator);
    }
}
