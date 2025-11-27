pragma solidity ^0.8.0;

import {ICVYDao} from './interfaces/ICVYDao.sol';
import {SafeERC20} from '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import {IERC20} from '@openzeppelin/contracts/token/ERC20/IERC20.sol';

contract CVYDao is ICVYDao {
    using SafeERC20 for IERC20;

    address public governanceToken;
    address public proposalImplementation;
    address public crowdFundImplementation;
    uint256 public proposalCount;
    mapping(address => bool) public isBanned;
    uint256 public stakeTokenAmountUSD;

    address[] public proposals;
    mapping(address => bool) public isProposal;

    uint256 public tokenId;
    mapping(uint256 => uint256) public stakeBalanceOfSBT;

    OperationsConfig private operationsConfig;

    constructor(
        address _governanceToken,
        address _proposalImplementation,
        address _crowdFundImplementation
    ) {
        governanceToken = _governanceToken;
        proposalImplementation = _proposalImplementation;
        crowdFundImplementation = _crowdFundImplementation;

        operationsConfig.feePerKilometerUSD = 100; // $1.00
        operationsConfig.requestPersistenceDuration = 15 minutes;
        operationsConfig.driverStakeAmountUSD = 500; // $5.00
        operationsConfig.cancellationPercentage = 99; // 0.99%
        operationsConfig.minFarePerRideTypeUSD[
            Constants.RideType.STANDARD
        ] = 200; // $2.00
        operationsConfig.minFarePerRideTypeUSD[
            Constants.RideType.COMFORT
        ] = 500; // $5.00
        operationsConfig.minFarePerRideTypeUSD[
            Constants.RideType.PREMIUM
        ] = 1000; // $10.00
        operationsConfig.minFarePerRideTypeUSD[Constants.RideType.XL] = 800; // $8.00
        operationsConfig.minFarePerRideTypeUSD[
            Constants.RideType.ELECTRIC
        ] = 2000; // $20.00
        operationsConfig.minFarePerRideTypeUSD[
            Constants.RideType.PARCEL_DELIVERY
        ] = 5000; // $50.00
    }

    function getOperationsConfig()
        external
        view
        returns (
            uint24 feePerKilometerUSD,
            uint256 requestPersistenceDuration,
            uint256 driverStakeAmountUSD,
            uint24 cancellationPercentage,
            Constants.RideType[] memory rideTypes,
            uint256[] memory minFaresPerRideTypeUSD
        )
    {
        feePerKilometerUSD = operationsConfig.feePerKilometerUSD;
        requestPersistenceDuration = operationsConfig
            .requestPersistenceDuration;
        driverStakeAmountUSD = operationsConfig.driverStakeAmountUSD;
        cancellationPercentage = operationsConfig.cancellationPercentage;
        rideTypes = new Constants.RideType[](6);
        minFaresPerRideTypeUSD = new uint256[](6);

        for (uint8 i = 0; i < 6; i++) {
            Constants.RideType rideType = Constants.RideType(i);
            rideTypes[i] = rideType;
            minFaresPerRideTypeUSD[i] = operationsConfig.minFarePerRideTypeUSD[
                rideType
            ];
        }
    }
}
