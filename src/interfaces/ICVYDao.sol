pragma solidity ^0.8.0;

import '../shared/Constants.sol' as Constants;

struct OperationsConfig {
    uint24 feePerKilometerUSD;
    uint256 requestPersistenceDuration;
    uint256 driverStakeAmountUSD;
    uint24 cancellationPercentage;
    mapping(Constants.RideType => uint256) minFarePerRideTypeUSD;
}

struct StakeInfo {
    uint256 stakedAmount;
    uint256 stakedOn;
    uint256 unlockTime;
}

interface ICVYDao {
    // === Error Definitions === //
    error UserBanned(address user);
    error NoStake();
    error StakeDurationTooLong(uint256 maxDuration);
    error NotYetUnlocked(uint256 unlockTime);
    error SBT(uint256 tokenId);
    error NotTokenOwner(address owner, uint256 tokenId);
    error OnlyProposal();

    // === Events === //
    event ProposalCreated(address proposal, string title, string description, uint256 duration);
    event CrowdFundCreated(address crowdFund, string description);

    //=== View Functions ===//
    function MAX_STAKE_DURATION() external view returns (uint256);
    function governanceToken() external view returns (address);
    function stakeInfoOfSBT(uint256 tokenId) external view returns (StakeInfo memory);
    function tokenId() external view returns (uint256);
    function proposalImplementation() external view returns (address);
    function crowdFundImplementation() external view returns (address);
    function proposalCount() external view returns (uint256);
    function proposals(uint256 index) external view returns (address);
    function crowdFundCount() external view returns (uint256);
    function crowdFunds(uint256 index) external view returns (address);
    function isProposal(address proposal) external view returns (bool);
    function sbtWeight(uint256 tokenId) external view returns (uint256);
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
        );
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
        );

    //=== State Changing Functions ===//
    function stake(uint256 amount, uint256 duration) external;
    function unstake(uint256 tokenId) external;
    function createProposal(
        uint256 tokenId,
        string calldata title,
        string calldata description,
        uint256 duration,
        bytes[] memory callData
    ) external returns (address);
    function createCrowdFund(
        address fundingToken,
        address recipient,
        uint256 targetAmount,
        string memory description,
        address[] memory callTargets,
        bytes[] memory callData
    ) external returns (address);
    function setOperationsConfig(
        uint24 feePerKilometerUSD,
        uint256 requestPersistenceDuration,
        uint256 driverStakeAmountUSD,
        uint24 cancellationPercentage,
        Constants.RideType[] calldata rideTypes,
        uint256[] calldata minFaresUSD
    ) external;
    function banUser(address user) external;
    function unbanUser(address user) external;
    function withdrawERC20(address token, address to, uint256 amount) external;
}
