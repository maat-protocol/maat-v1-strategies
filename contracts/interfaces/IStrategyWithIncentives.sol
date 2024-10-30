// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.20;

interface IStrategyWithIncentives {
    function totalIncentives() external returns (uint256 incentives);

    function harvest()
        external
        returns (address[] memory rewardTokens, uint256[] memory rewards);

    function previewHarvest()
        external
        view
        returns (address[] memory rewardTokens, uint256[] memory rewards);

    function compound(uint256 amount) external;

    function StrategyWithIncentivesInterfaceId() external returns (bytes4);
}
