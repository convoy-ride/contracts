pragma solidity ^0.8.0;

import {ICVYEscrow} from './interfaces/ICVYEscrow.sol';
import {ICVYDao} from './interfaces/ICVYDao.sol';
import {SafeERC20} from '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import {IERC20} from '@openzeppelin/contracts/token/ERC20/IERC20.sol';

contract CVYEscrow is ICVYEscrow {
    using SafeERC20 for IERC20;

    address public factory;
    address public driver;
    address public rider;
    address public token;
    address public dao;

    uint256 public amount;
    uint256 public stakedAmount;

    bytes32 public rideId;

    bool public isReleased;

    function initialize(
        address _rider,
        address _token,
        uint256 _amount,
        bytes32 _rideId,
        address _dao
    ) external {
        if (factory != address(0)) revert AlreadyInitialized();
        factory = msg.sender;
        rider = _rider;
        token = _token;
        amount = _amount;
        rideId = _rideId;
        dao = _dao;
    }

    function setDriver(address _driver) external {
        if (msg.sender != factory) revert OnlyFactory();
        if (driver != address(0)) revert DriverAlreadySet();
        driver = _driver;
    }

    function stake(uint256 _amount) external {
        if (msg.sender != factory) revert OnlyFactory();
        address _stakeToken = ICVYDao(dao).governanceToken();
        IERC20(_stakeToken).safeTransferFrom(driver, address(this), _amount);
        stakedAmount = _amount;
    }

    function collectPayment() external {
        if (msg.sender != factory) revert OnlyFactory();
        IERC20(token).safeTransferFrom(rider, address(this), amount);
    }
}
