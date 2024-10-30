// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.22;

import {IIncentiveController} from "./interfaces/IIncentiveController.sol";
import {IStrategyWithIncentives} from "./interfaces/IStrategyWithIncentives.sol";
import {ISwapRouter} from "./interfaces/ISwapRouter.sol";
import {IStrategy} from "./interfaces/IStrategy.sol";

import {ERC165Registry, IERC165} from "./lib/ERC165Registry.sol";

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract IncentiveController is IIncentiveController, Ownable, ERC165Registry {
    using SafeERC20 for IERC20;

    error OnlyCompounder();
    error OnlySupportedRouter();
    error SwapDataLengthMismatch(
        uint8 rewardTokensLength,
        uint8 swapsDataLength
    );

    event NewCompounder(address previousCompounder, address compounder);
    event SwapRouterAdded(address swapRouter);
    event SwapRouterRemoved(address swapRouter);

    bytes4 constant IncentiveControllerInterfaceId =
        bytes4(keccak256("MAAT.V1.IncentiveController"));

    mapping(address => bool) public isSupportedRouter;

    address[] _routers;

    address public compounder;

    constructor(address _admin, address _compounder) Ownable(_admin) {
        compounder = _compounder;

        _registerInterface(IncentiveControllerInterfaceId);
    }

    function harvestAndCompound(
        address swapRouter,
        IStrategyWithIncentives strategyWithIncentives,
        bytes[] calldata swapsData
    ) external {
        if (msg.sender != compounder) revert OnlyCompounder();
        if (!isSupportedRouter[swapRouter]) revert OnlySupportedRouter();

        (
            address[] memory rewardTokens,
            uint256[] memory rewards
        ) = strategyWithIncentives.harvest();

        emit Harvest(rewardTokens, rewards);

        if (rewardTokens.length != swapsData.length)
            revert SwapDataLengthMismatch(
                uint8(rewardTokens.length),
                uint8(swapsData.length)
            );

        address asset = IStrategy(address(strategyWithIncentives)).asset();
        uint totalAmountToReInvest;

        for (uint i = 0; i < rewardTokens.length; i++) {
            address rewardToken = rewardTokens[i];
            uint256 reward = rewards[i];
            IERC20 token = IERC20(rewardToken);

            token.approve(swapRouter, reward);

            uint256 amountOut = _swap(
                swapRouter,
                rewardToken,
                asset,
                reward,
                swapsData[i]
            );

            totalAmountToReInvest += amountOut;

            uint256 dust = token.balanceOf(address(this));
            if (dust > 0)
                token.safeTransfer(address(strategyWithIncentives), dust);
        }

        IERC20(asset).safeTransfer(
            address(strategyWithIncentives),
            totalAmountToReInvest
        );

        strategyWithIncentives.compound(totalAmountToReInvest);

        emit Compound(address(strategyWithIncentives), totalAmountToReInvest);
    }

    function routers() external view returns (address[] memory) {
        return _routers;
    }

    // ===================
    //        ADMIN
    // ===================

    function changeCompounder(address newCompounder) external onlyOwner {
        emit NewCompounder(compounder, newCompounder);
        compounder = newCompounder;
    }

    function addSwapRouter(address swapRouter) external onlyOwner {
        isSupportedRouter[swapRouter] = true;

        _routers.push(swapRouter);

        emit SwapRouterAdded(swapRouter);
    }

    function removeSwapRouter(address swapRouter) external onlyOwner {
        isSupportedRouter[swapRouter] = false;

        _removeAddress(swapRouter);

        emit SwapRouterRemoved(swapRouter);
    }

    function _removeAddress(address addressToRemove) internal {
        uint256 arrayLength = _routers.length;
        address[] memory array = _routers;
        if (arrayLength == 1) {
            _routers.pop();
            return;
        }
        for (uint i = 0; i < arrayLength; i++) {
            if (array[i] == addressToRemove) {
                _routers[i] = array[arrayLength - 1];
                _routers.pop();
                break;
            }
        }
    }

    function _swap(
        address swapRouter,
        address tokenIn,
        address tokenOut,
        uint256 amountIn,
        bytes memory swapData
    ) internal returns (uint256 amountOut) {
        uint256 assetBalanceBefore = IERC20(tokenOut).balanceOf(address(this));
        ISwapRouter(swapRouter).swap(tokenIn, amountIn, swapData);
        uint256 assetBalanceAfter = IERC20(tokenOut).balanceOf(address(this));

        amountOut = assetBalanceAfter - assetBalanceBefore;

        emit Swap(tokenIn, tokenOut, amountIn, amountOut);
    }
}
