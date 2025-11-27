pragma solidity ^0.8.0;

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

    // === Operational Parameters === //
    function feePerDistanceUSD() external view returns (uint256);
    function requestPersistenceDuration() external view returns (uint256);
    function isBanned(address user) external view returns (bool);
    function stakeTokenAmountUSD() external view returns (uint256);

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
    ) external;
    function setFeePerDistanceUSD(uint256 newFee) external;
    function setRequestPersistenceDuration(uint256 newDuration) external;
    function banUser(address user) external;
    function unbanUser(address user) external;
    function withdrawERC20(address token, address to, uint256 amount) external;
}
