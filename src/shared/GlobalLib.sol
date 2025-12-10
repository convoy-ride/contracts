pragma solidity ^0.8.0;

import {IERC20Permit} from '@openzeppelin/contracts/tokens/ERC20/extensions/IERC20Permit.sol';

library GlobalLib {
    function composePermitCallData(
        address owner,
        address spender,
        uint256 amount,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal returns (bytes memory) {
        return
            abi.encodeWithSelector(IERC20Permit.permit, owner, spender, amount, deadline, v, r, s);
    }
}
