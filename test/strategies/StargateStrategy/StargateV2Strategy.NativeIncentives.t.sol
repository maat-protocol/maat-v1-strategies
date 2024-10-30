// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./_StargateV2Strategy.Setup.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract StargateV2StrategyNativeIncentivesTestSetup is
    StargateV2StrategyTestSetup
{
    uint48[] allocPoints = [uint48(10000)];

    address stakingToken = 0x6Ea313859A5D9F6fF2a68f529e6361174bFD2225; // USDC LP
    IERC20[] stakingTokens = [IERC20(stakingToken)];

    function _afterSetUp() internal override {
        _prepareTokens();
        address rewardToken = 0x0000000000000000000000000000000000000000;
        uint amount = 2 ether;
        uint48 start = uint48(block.timestamp);
        uint48 duration = 10 days;

        vm.deal(address(this), amount);

        vm.startPrank(address(stargateMultiRewarder.owner()));

        stargateMultiRewarder.setReward{value: amount}(
            rewardToken,
            amount,
            start,
            duration
        );
        stargateMultiRewarder.setAllocPoints(
            rewardToken,
            stakingTokens,
            allocPoints
        );

        vm.stopPrank();
    }

    function test_deposit_with_native_incentives() public {
        StargateV2Strategy _strategy = StargateV2Strategy(
            payable(address(strategy))
        );

        uint256 amount = formatDecimals(100);
        uint256 balanceBefore = token.balanceOf(maatVault);
        vm.prank(maatVault);
        _strategy.deposit(amount, maatVault);

        assertEq(_strategy.balanceOf(address(maatVault)), amount);
        assertEq(token.balanceOf(maatVault), balanceBefore - amount);
        assertEq(_strategy.totalAssets(), amount);
        assertEq(_strategy.totalSupply(), amount);

        vm.warp(block.timestamp + 5 days);

        _strategy.pendingRewards();

        vm.warp(block.timestamp + 5 days);

        _strategy.withdraw(amount, maatVault, maatVault);
    }
}
