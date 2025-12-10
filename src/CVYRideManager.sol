pragma solidity ^0.8.0;

import {
    ICVYRideManager,
    RideEvent,
    Geocoordinates,
    RideStatus
} from './interfaces/ICVYRideManager.sol';
import {ICVYDao} from './interfaces/ICVYDao.sol';
import {ICVYEscrow} from './interfaces/ICVYEscrow.sol';
import {GlobalLib} from './shared/GlobalLib.sol';
import {Clones} from '@openzeppelin/contracts/proxy/Clones.sol';
import {ERC2771Context} from '@openzeppelin/contracts/metatx/ERC2771Context.sol';
import {Address} from '@openzeppelin/contracts/utils/Address.sol';

contract CVYRideManager is ICVYRideManager, ERC2771Context {
    using GlobalLib for address;
    using Address for address;

    address public immutable escrowImplementation;
    address public immutable stakeToken;
    address public immutable dao;

    mapping(bytes32 => RideEvent) public rides;
    mapping(string => bytes32) public offChainIDToRideID;
    mapping(bytes32 => address) public escrow;

    bytes32[] public allRides;

    constructor(
        address _escrowImplementation,
        address _dao,
        address trustedForwarder_
    ) ERC2771Context(trustedForwarder_) {
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
            endTimestamp: 0,
            status: RideStatus.Pending,
            cancelledBy: address(0)
        });

        bytes32 salt = keccak256(abi.encodePacked(_rideId, offChainID));
        _escrow = Clones.cloneDeterministic(escrowImplementation, salt);
        (uint8 v, bytes32 r, bytes32 s) = abi.decode(permitData, (uint8, bytes32, bytes32));
        (, uint256 persistenceDuration, , , , ) = ICVYDao(dao).getOperationsConfig();
        fareToken.functionCall(
            sender.composePermitCallData(
                _escrow,
                fareAmount,
                block.timestamp + persistenceDuration,
                v,
                r,
                s
            )
        );

        ICVYEscrow(_escrow).initialize(sender, fareToken, fareAmount, _rideId, dao);

        allRides.push(_rideId);
        escrow[_rideId] = _escrow;
    }

    function consentToDrive(bytes32 rideId, bytes calldata permitData) external {
        address sender = _msgSender();
        address _escrow = escrow[rideId];
        RideEvent storage ride = rides[rideId];
        ride.driver = sender;
        ride.startTimestamp = block.timestamp;
        ride.status = RideStatus.Started;

        (uint8 v, bytes32 r, bytes32 s) = abi.decode(permitData, (uint8, bytes32, bytes32));
        (, , uint256 stakeAmountUSD, , , ) = ICVYDao(dao).getOperationsConfig();
        // TO DO: Query price oracle and use value instead
        stakeToken.functionCall(
            sender.composePermitCallData(
                _escrow,
                stakeAmountUSD,
                block.timestamp + 20 minutes,
                v,
                r,
                s
            )
        );
        ICVYEscrow(_escrow).setDriver(sender);
        ICVYEscrow(_escrow).stake(stakeAmountUSD);
        ICVYEscrow(_escrow).collectPayment();
    }

    function completeRide(bytes32 rideId) external {
        address sender = _msgSender();
        address _escrow = escrow[rideId];
        RideEvent storage ride = rides[rideId];

        if (ride.driver != sender) revert Unauthorized();

        ride.endTimestamp = block.timestamp;
        ride.status = RideStatus.Completed;
        ICVYEscrow(_escrow).releaseFunds();
    }

    function cancelRide(bytes32 rideId) external {
        address sender = _msgSender();
        address _escrow = escrow[rideId];
        RideEvent storage ride = rides[rideId];

        if (ride.rider != sender && ride.driver != sender) revert Unauthorized();

        ride.endTimestamp = block.timestamp;
        ride.cancelledBy = sender;
        ride.status = RideStatus.Cancelled;
        ICVYEscrow(_escrow).releaseFunds();
    }
}
