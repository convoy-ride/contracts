pragma solidity ^0.8.0;

interface ICVYCrowdFund {
    // === View Functions === //
    function factory() external view returns (address);

    // === State Changing Functions === //
    function initialize(
        address fundingToken,
        address recipient,
        uint256 targetAmount,
        address[] callTargets,
        bytes[] callData
    ) external;
}
