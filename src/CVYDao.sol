pragma solidity ^0.8.0;

import {ICVYDao} from './interfaces/ICVYDao.sol';
import {ICVYProposal} from './interfaces/ICVYProposal.sol';
import {ICVYCrowdFund} from './interfaces/ICVYCrowdFund.sol';
import {SafeERC20} from '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import {IERC20} from '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import {ERC721} from '@openzeppelin/contracts/token/ERC721/ERC721.sol';
import {Clones} from '@openzeppelin/contracts/proxy/Clones.sol';

contract CVYDao is ICVYDao, ERC721 {
    using SafeERC20 for IERC20;

    uint256 public constant MAX_STAKE_DURATION = 730 days; // 2 years
    uint256 private constant WEIGHT_MULTIPLIER = 50; // 0.5
    address public governanceToken;
    address public proposalImplementation;
    address public crowdFundImplementation;
    uint256 public proposalCount;
    uint256 public crowdFundCount;
    mapping(address => bool) public isBanned;
    uint256 public stakeTokenAmountUSD;
    address[] public proposals;
    address[] public crowdFunds;
    mapping(address => bool) public isProposal;
    uint256 public tokenId;
    mapping(uint256 => StakeInfo) public stakeInfoOfSBT;
    OperationsConfig private operationsConfig;

    constructor(
        address _governanceToken,
        address _proposalImplementation,
        address _crowdFundImplementation
    ) ERC721('Convoy DAO', 'CVYDAO') {
        governanceToken = _governanceToken;
        proposalImplementation = _proposalImplementation;
        crowdFundImplementation = _crowdFundImplementation;

        operationsConfig.feePerKilometerUSD = 100; // $1.00
        operationsConfig.requestPersistenceDuration = 15 minutes;
        operationsConfig.driverStakeAmountUSD = 500; // $5.00
        operationsConfig.cancellationPercentage = 99; // 0.99%
        operationsConfig.minFarePerRideTypeUSD[Constants.RideType.STANDARD] = 200; // $2.00
        operationsConfig.minFarePerRideTypeUSD[Constants.RideType.COMFORT] = 500; // $5.00
        operationsConfig.minFarePerRideTypeUSD[Constants.RideType.PREMIUM] = 1000; // $10.00
        operationsConfig.minFarePerRideTypeUSD[Constants.RideType.XL] = 800; // $8.00
        operationsConfig.minFarePerRideTypeUSD[Constants.RideType.ELECTRIC] = 2000; // $20.00
        operationsConfig.minFarePerRideTypeUSD[Constants.RideType.PARCEL_DELIVERY] = 5000; // $50.00
    }

    function stake(uint256 amount, uint256 duration) external {
        address sender = msg.sender;
        tokenId++;
        _mint(sender, tokenId);

        if (duration > MAX_STAKE_DURATION) {
            revert StakeDurationTooLong(MAX_STAKE_DURATION);
        }

        uint256 unlockTime = block.timestamp + duration;
        IERC20(governanceToken).safeTransferFrom(sender, address(this), amount);
        stakeInfoOfSBT[_tokenId] = StakeInfo({
            stakedAmount: amount,
            stakedOn: block.timestamp,
            unlockTime: unlockTime
        });
    }

    function unstake(uint256 _tokenId) external {
        address sender = msg.sender;
        if (ownerOf(_tokenId) != sender) {
            revert NoStake();
        }
        StakeInfo storage info = stakeInfoOfSBT[_tokenId];
        if (block.timestamp < info.unlockTime) {
            revert NotYetUnlocked(info.unlockTime);
        }

        IERC20(governanceToken).safeTransfer(sender, info.stakedAmount);
        info.stakedAmount = 0;
    }

    function createProposal(
        uint256 _tokenId,
        string memory title,
        string memory description,
        uint256 duration,
        bytes[] memory callData
    ) external returns (address proposal) {
        address sender = msg.sender;
        if (ownerOf(_tokenId) != sender) {
            revert NotTokenOwner(sender, _tokenId);
        }
        bytes32 salt = keccak256(
            abi.encodePacked(_tokenId, title, description, duration, callData, block.timestamp)
        );
        proposal = Clones.cloneDeterministic(proposalImplementation, salt);
        uint256 quorum = _calculateProposalQuorum(_tokenId);
        ICVYProposal(proposal).initialize(sender, title, description, duration, quorum, callData);

        proposals.push(proposal);
        isProposal[proposal] = true;
        proposalCount++;

        emit ProposalCreated(proposal, title, description, duration);
    }

    function createCrowdFund(
        address fundingToken,
        address recipient,
        uint256 targetAmount,
        string memory description,
        address[] memory callTargets,
        bytes[] memory callData
    ) external returns (address crowdFund) {
        if (!isProposal[msg.sender]) {
            revert OnlyProposal();
        }

        bytes32 salt = keccak256(
            abi.encodePacked(
                fundingToken,
                recipient,
                targetAmount,
                callTargets,
                callData,
                description,
                block.timestamp
            )
        );
        crowdFund = Clones.cloneDeterministic(crowdFundImplementation, salt);
        ICVYCrowdFund(crowdFund).initialize(
            fundingToken,
            recipient,
            targetAmount,
            description,
            callTargets,
            callData
        );
        crowdFunds.push(crowdFund);
        crowdFundCount++;
        emit CrowdFundCreated(crowdFund, description);
    }

    function setOperationsConfig(
        uint24 feePerKilometerUSD,
        uint256 requestPersistenceDuration,
        uint256 driverStakeAmountUSD,
        uint24 cancellationPercentage,
        Constants.RideType[] calldata rideTypes,
        uint256[] calldata minFaresUSD
    ) external {
        if (!isProposal[msg.sender]) {
            revert OnlyProposal();
        }
        require(rideTypes.length == minFaresUSD.length, 'Length_Mismatch');
        operationsConfig.feePerKilometerUSD = feePerKilometerUSD;
        operationsConfig.requestPersistenceDuration = requestPersistenceDuration;
        operationsConfig.driverStakeAmountUSD = driverStakeAmountUSD;
        operationsConfig.cancellationPercentage = cancellationPercentage;

        for (uint8 i; i < rideTypes.length; i++) {
            operationsConfig.minFarePerRideTypeUSD[rideTypes[i]] = minFaresUSD[i];
        }
    }

    function banUser(address user) external {
        if (!isProposal[msg.sender]) {
            revert OnlyProposal();
        }

        isBanned[user] = true;
    }

    function unbanUser(address user) external {
        if (!isProposal[msg.sender]) {
            revert OnlyProposal();
        }
        isBanned[user] = false;
    }

    function sbtWeight(uint256 _tokenId) public view returns (uint256) {
        StakeInfo memory info = stakeInfoOfSBT[_tokenId];
        uint256 duration = block.timestamp - info.stakedOn;
        return (info.stakedAmount * duration) / MAX_STAKE_DURATION;
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
        requestPersistenceDuration = operationsConfig.requestPersistenceDuration;
        driverStakeAmountUSD = operationsConfig.driverStakeAmountUSD;
        cancellationPercentage = operationsConfig.cancellationPercentage;
        rideTypes = new Constants.RideType[](6);
        minFaresPerRideTypeUSD = new uint256[](6);

        for (uint8 i = 0; i < 6; i++) {
            Constants.RideType rideType = Constants.RideType(i);
            rideTypes[i] = rideType;
            minFaresPerRideTypeUSD[i] = operationsConfig.minFarePerRideTypeUSD[rideType];
        }
    }

    function proposalMetadata(
        address proposal
    )
        external
        view
        returns (
            string memory title,
            string memory description,
            uint256 duration,
            bytes[] memory callData,
            uint8 state,
            uint256 start,
            uint256 assent,
            uint256 dissent,
            uint256 abstainment,
            uint256 quorum
        )
    {
        ICVYProposal prop = ICVYProposal(proposal);
        title = prop.title();
        description = prop.description();
        duration = prop.duration();
        callData = prop.callData();
        state = prop.state();
        start = prop.start();
        assent = prop.assent();
        dissent = prop.dissent();
        abstainment = prop.abstainment();
        quorum = prop.quorum();
    }

    function _calculateProposalQuorum(uint256 _tokenId) internal view returns (uint256) {
        uint256 totalSBTWeight = 0;
        for (uint256 i = 1; i <= tokenId; i++) {
            totalSBTWeight += sbtWeight(i);
        }
        uint256 baseQuorum = (1000 * totalSBTWeight) / 10000; // 10% of total weight
        uint256 wXWeightMultiplier = (sbtWeight(_tokenId) * WEIGHT_MULTIPLIER) / 100;
        return baseQuorum + wXWeightMultiplier;
    }

    function _update(
        address to,
        uint256 _tokenId,
        address auth
    ) internal virtual override returns (address) {
        address _owner = _ownerOf(_tokenId);
        if (_owner != address(0)) revert SBT(_tokenId);
        return super._update(to, _tokenId, auth);
    }
}
