pragma solidity ^0.8.0;

import {ERC20Permit} from '@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol';

contract CVY is ERC20Permit {
    constructor(
        address to,
        uint256 amount
    ) ERC20Permit('Convoy Token') ERC20('Convoy Token', 'CVY') {
        _mint(to, amount);
    }
}
