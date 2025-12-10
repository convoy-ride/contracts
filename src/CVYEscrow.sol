pragma solidity ^0.8.0;

import {ICVYEscrow} from './interfaces/ICVYEscrow.sol';

contract CVYEscrow is ICVYEscrow {
    address public factory;
    address public driver;
    address public rider;
    address public token;

    uint256 public amount;
    uint256 public stakedAmount;

    bytes32 public rideId;

    bool public isReleased;

    function initialize(address _rider, address _token, uint256 _amount, bytes32 _rideId) external {
        if (factory != address(0)) revert AlreadyInitialized();
        factory = msg.sender;
        rider = _rider;
        token = _token;
        amount = _amount;
        rideId = _rideId;
    }
}
