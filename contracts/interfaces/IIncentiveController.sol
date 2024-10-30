// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.22;
import {IStrategyWithIncentives} from "./IStrategyWithIncentives.sol";

interface IIncentiveController {
    event Harvest(address[] rewardTokens, uint256[] rewards);
    event Swap(
        address tokenIn,
        address tokenOut,
        uint256 amountIn,
        uint256 amountOut
    );
    event Compound(address strategy, uint256 amount);

    function harvestAndCompound(
        address swapRouter,
        IStrategyWithIncentives strategiesWithIncentives,
        bytes[] calldata swapData
    ) external;

    function routers() external view returns (address[] memory);
}
