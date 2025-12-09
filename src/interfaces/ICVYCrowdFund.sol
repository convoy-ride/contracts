pragma solidity ^0.8.0;

interface ICVYCrowdFund {
    // === Errors === //
    error AlreadyInitialized();
    error NoDeposit();
    error OnlyRecipient();
    error TargetNotReached();
    error AlreadyCompleted();

    // === View Functions === //
    function factory() external view returns (address);
    function ETHER() external view returns (address);
    function targetAmount() external view returns (uint256);
    function description() external view returns (string);
    function callTargets(uint256 index) external view returns (address);
    function callData(uint256 index) external view returns (bytes memory);
    function fundingToken() external view returns (address);
    function recipient() external view returns (address);

    // === State Changing Functions === //
    function initialize(
        address fundingToken,
        address recipient,
        uint256 targetAmount,
        string memory description,
        address[] memory callTargets,
        bytes[] memory callData
    ) external;
    function fund(
        uint256 amount,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external payable;
    function withdraw() external;
    function complete() external;
}
