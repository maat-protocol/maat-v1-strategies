// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.22;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import {StargateV2StrategyTestSetup, StargateV2Strategy} from "./_StargateV2Strategy.Setup.sol";

contract StargateV2HarvestTest is StargateV2StrategyTestSetup {
    function test_previewHarvest() public {
        StargateV2Strategy strategy = StargateV2Strategy(payable(address(strategy)));

        vm.prank(admin);
        maatAddressProvider.changeIncentiveController(address(this));

        uint256 amount = formatDecimals(100);
        strategy.deposit(amount, maatVault);

        skip(100 days);

        {
            (address[] memory rewardTokens, uint256[] memory rewards) = strategy
                .pendingRewards();

            assertEq(rewardTokens.length, rewards.length);
            assertNotEq(rewardTokens.length, 0);
        }

        (address[] memory rewardTokens, uint256[] memory rewards) = strategy
            .previewHarvest();

        assertEq(rewardTokens.length, rewards.length);
        assertNotEq(rewardTokens.length, 0);
        for (uint256 i = 0; i < rewardTokens.length; i++) {
            assertGt(rewards[i], 0);
        }
    }

    function test_harvest() public {
        StargateV2Strategy strategy = StargateV2Strategy(payable(address(strategy)));

        vm.prank(admin);
        maatAddressProvider.changeIncentiveController(address(this));

        uint256 amount = formatDecimals(100);
        strategy.deposit(amount, maatVault);

        skip(100 days);

        (address[] memory rewardTokens, uint256[] memory rewards) = strategy
            .harvest();

        assertEq(rewardTokens.length, rewards.length);
        assertGt(rewardTokens.length, 0);
        for (uint256 i = 0; i < rewardTokens.length; i++) {
            assertGt(rewards[i], 0);
            assertEq(
                rewards[i],
                IERC20(rewardTokens[i]).balanceOf(
                    maatAddressProvider.incentiveController()
                )
            );
        }
    }

    function test_compound() public {
        StargateV2Strategy strategy = StargateV2Strategy(payable(address(strategy)));

        vm.prank(admin);
        maatAddressProvider.changeIncentiveController(address(this));

        uint256 amount = formatDecimals(10);

        token.transfer(address(strategy), amount);

        strategy.compound(amount);

        assertEq(strategy.totalIncentives(), amount);
    }
}
