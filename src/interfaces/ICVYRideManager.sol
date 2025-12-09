pragma solidity ^0.8.0;

enum RideStatus {
    Created,
    Completed,
    Cancelled
}

struct GeoCoordinates {
    int32 latitude;
    int32 longitude;
    string locationName;
}

struct RideEvent {
    bytes32 rideId;
    GeoCoordinates pickupLocation;
    GeoCoordinates dropoffLocation;
    string offChainID;
    address rider;
    address driver;
    uint256 fareAmount;
    address fareToken;
    uint256 startTimestamp;
    uint256 endTimestamp;
    RideStatus status;
}

interface ICVYRideManager {
    event RideCreated(
        bytes32 indexed rideId,
        address indexed rider,
        uint256 fareAmount,
        address fareToken
    );
    event DriverConsented(bytes32 indexed rideId, address indexed driver);
    event RideCompleted(bytes32 indexed rideId);

    // === View Functions === //
    function escrowImplementation() external view returns (address);
    function rides(bytes32 rideId) external view returns (RideEvent memory);
    function offChainIDToRideID(
        string calldata offChainID
    ) external view returns (bytes32);
    function escrow(bytes32 rideId) external view returns (address);
    function stakeToken() external view returns (address);
    function dao() external view returns (address);

    // === State Changing Functions === //
    function createRideEvent(
        GeoCoordinates calldata pickupLocation,
        GeoCoordinates calldata dropoffLocation,
        string calldata offChainID,
        uint256 fareAmount,
        address fareToken,
        bytes calldata permitData
    ) external returns (bytes32, address);
    function consentToDrive(bytes32 rideId, bytes calldata permitData) external;
    function completeRide(bytes32 rideId) external;
    function cancelRide(bytes32 rideId) external;
}
