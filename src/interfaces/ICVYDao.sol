pragma solidity ^0.8.0;

import '../shared/Constants.sol' as Constants;

struct OperationsConfig {
    uint24 feePerKilometerUSD;
    uint256 requestPersistenceDuration;
    uint256 driverStakeAmountUSD;
    uint24 cancellationPercentage;
    mapping(Constants.RideType => uint256) minFarePerRideTypeUSD;
}

interface ICVYDao {
    //=== View Functions ===//
    function governanceToken() external view returns (address);
    function stakeBalanceOfSBT(uint256 tokenId) external view returns (uint256);
    function tokenId() external view returns (uint256);
    function proposalImplementation() external view returns (address);
    function crowdFundImplementation() external view returns (address);
    function proposalCount() external view returns (uint256);
    function proposals(uint256 index) external view returns (address);
    function isProposal(address proposal) external view returns (bool);
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
    function stake(uint256 amount) external;
    function unstake(uint256 amount) external;
    function createProposal(
        string calldata title,
        string calldata description,
        uint256 duration,
        bytes[] memory callData
    ) external returns (address);
    function createCrowdFund(
        address fundingToken,
        address recipient,
        uint256 targetAmount,
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
