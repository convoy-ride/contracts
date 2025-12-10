pragma solidity ^0.8.0;

interface ICVYEscrow {
    // === Errors === //
    error AlreadyInitialized();

    // === View Functions === //
    function factory() external view returns (address);
    function driver() external view returns (address);
    function rider() external view returns (address);
    function token() external view returns (address);
    function amount() external view returns (uint256);
    function rideId() external view returns (bytes32);
    function isReleased() external view returns (bool);
    function stakedAmount() external view returns (uint256);

    // === State Changing Functions === //
    function initialize(address rider, address token, uint256 amount, bytes32 rideId) external;
    function setDriver(address user) external;
    function stake(uint256 amount) external;
    function collectPayment() external;
    function releaseFunds() external;
}
