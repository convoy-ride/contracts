pragma solidity ^0.8.0;

import {
    ICVYRideManager,
    RideEvent,
    Geocoordinates,
    RideStatus
} from './interfaces/ICVYRideManager.sol';
import {ICVYDao} from './interfaces/ICVYDao.sol';
import {Clones} from '@openzeppelin/contracts/proxy/Clones.sol';

contract CVYRideManager is ICVYRideManager {
    address public immutable escrowImplementation;
    address public immutable stakeToken;
    address public immutable dao;

    mapping(bytes32 => RideEvent) public rides;
    mapping(string => bytes32) public offChainIDToRideID;
    mapping(bytes32 => address) public escrow;

    bytes32[] private _rides;

    constructor(address _escrowImplementation, address _dao) {
        escrowImplementation = _escrowImplementation;
        dao = _dao;
        stakeToken = ICVYDao(dao).governanceToken();
    }

    function createRideEvent(
        GeoCoordinates memory pickupLocation,
        GeoCoordinates memory dropoffLocation,
        string memory offChainID,
        uint256 fareAmount,
        address fareToken,
        bytes calldata permitData
    ) external returns (bytes32 _rideId, address _escrow) {
        address sender = _msgSender();
        _rideId = keccak256(abi.encode(offChainID));
        offChainIDToRideID[offChainID] = _rideId;
        rides[_rideId] = RideEvent({
            rideId: _rideId,
            pickupLocation: pickupLocation,
            dropoffLocation: dropoffLocation,
            offChainID: offChainID,
            rider: sender,
            driver: address(0),
            fareAmount: fareAmount,
            fareToken: fareToken,
            startTimestamp: 0,
            endTimestamp: 0
        });

        bytes32 salt = keccak256(abi.encodePacked(_rideId, offChainID));
        _escrow = Clones.cloneDeterministic(escrowImplementation, salt);
    }
}
