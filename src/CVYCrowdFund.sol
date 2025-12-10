pragma solidity ^0.8.0;

import {ICVYCrowdFund} from './interfaces/ICVYCrowdFund.sol';
import {GlobalLib} from './shared/GlobalLib.sol';
import {SafeERC20} from '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import {IERC20} from '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import {ERC2771Context} from '@openzeppelin/contracts/metatx/ERC2771Context.sol';
import {Address} from '@openzeppelin/contracts/utils/Address.sol';

contract CVYCrowdFund is ICVYCrowdFund, ERC2771Context {
    using SafeERC20 for IERC20;
    using Address for address;
    using GlobalLib for address;

    address public factory;
    address public ETHER;
    address public fundingToken;
    address public recipient;

    uint256 public targetAmount;

    string public description;

    address[] public callTargets;
    bytes[] public callData;

    mapping(address => uint256) private _deposits;
    bool private _isCompleted;

    constructor(address trustedForwarder_) ERC2771Context(trustedForwarder_) {}

    function initialize(
        address _fundingToken,
        address _recipient,
        uint256 _targetAmount,
        string memory _description,
        address[] memory _callTargets,
        bytes[] memory _callData
    ) external {
        if (factory != address(0)) revert AlreadyInitialized();
        factory = msg.sender;
        ETHER = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
        fundingToken = _fundingToken;
        recipient = _recipient;
        targetAmount = _targetAmount;
        description = _description;
        callTargets = _callTargets;
        callData = _callData;
        _isCompleted = false;
    }

    function fund(uint256 amount, uint8 v, bytes32 r, bytes32 s) external payable {
        if (_isCompleted) revert AlreadyCompleted();
        address sender = _msgSender();
        if (ETHER == fundingToken) {
            require(msg.value >= amount, 'Invalid_Msg.Value');
            _deposits[sender] += msg.value;
        } else {
            fundingToken.functionCall(
                sender.composePermitCallData(
                    address(this),
                    amount,
                    block.timestamp + 20 minutes,
                    v,
                    r,
                    s
                )
            );
            IERC20(fundingToken).safeTransferFrom(sender, address(this), amount);
            _deposits[sender] += amount;
        }
    }

    function withdraw() external {
        if (_isCompleted) revert AlreadyCompleted();
        address sender = _msgSender();
        uint256 deposited = _deposits[sender];
        if (deposited == 0) {
            revert NoDeposit();
        }

        if (ETHER == fundingToken) {
            sender.transfer(deposited);
        } else {
            IERC20(fundingToken).safeTransfer(sender, deposited);
        }

        _deposits[sender] = 0;
    }

    function complete() external {
        address sender = _msgSender();
        if (sender != recipient) revert OnlyRecipient();
        if (ETHER == fundingToken) {
            uint256 amount = address(this).balance;
            if (amount < targetAmount) revert TargetNotReached();
            recipient.transfer(amount);
        } else {
            uint256 amount = IERC20(fundingToken).balanceOf(address(this));
            if (amount < targetAmount) revert TargetNotReached();
            IERC20(fundingToken).safeTransfer(recipient, amount);
        }

        _isCompleted = true;

        // Call the targets with corresponing calldata
        for (uint i = 0; i < callTargets.length; i++) {
            address _target = callTargets[i];
            _target.call{value: 0}(callData[i]);
        }
    }

    // function _composePermitCallData(
    //     address owner,
    //     address spender,
    //     uint256 amount,
    //     uint256 deadline,
    //     uint8 v,
    //     bytes32 r,
    //     bytes32 s
    // ) private returns (bytes memory) {
    //     return
    //         abi.encodeWithSelector(IERC20Permit.permit, owner, spender, amount, deadline, v, r, s);
    // }
}
