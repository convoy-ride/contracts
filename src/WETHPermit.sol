pragma solidity ^0.8.0;

import {ERC20Permit} from '@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol';
import {IWETH} from './interfaces/IWETH.sol';

contract WETHPermit is ERC20Permit, IWETH {
    event Deposit(address indexed depositor, uint256 value);
    event Withdrawal(address indexed withdrawer, uint256 value);

    constructor() ERC20Permit('Wrapped Ether') ERC20('Wrapped Ether', 'WETH') {}

    function deposit() public payable {
        _mint(msg.sender, msg.value);
        emit Deposit(msg.sender, msg.value);
    }
    function withdraw(uint wad) public {
        require(balanceOf(msg.sender) >= wad);
        _burn(msg.sender, wad);
        payable(msg.sender).transfer(wad);
        emit Withdrawal(msg.sender, wad);
    }

    receive() external payable {
        deposit();
    }
}
