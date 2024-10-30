// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.22;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import {HarvestV2StrategyTestSetup} from "./_HarvestV2Strategy.Setup.sol";

import {HarvestV2Strategy} from "../../../contracts/strategies/Harvest/HarvestV2Strategy.sol";

contract HarvestV2HarvestTest is HarvestV2StrategyTestSetup {
    function test_previewHarvest() public {
        HarvestV2Strategy strategy = HarvestV2Strategy(address(strategy));

        vm.prank(admin);
        maatAddressProvider.changeIncentiveController(address(this));

        uint256 amount = formatDecimals(100);
        strategy.deposit(amount, maatVault);

        skip(100 days);

        {
            (
                address[] memory _rewardTokens,
                uint256[] memory _rewards
            ) = strategy.pendingRewards(true);

            assertEq(_rewardTokens.length, _rewards.length);
            assertNotEq(_rewardTokens.length, 0);
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
        HarvestV2Strategy strategy = HarvestV2Strategy(address(strategy));

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
        HarvestV2Strategy strategy = HarvestV2Strategy(address(strategy));

        vm.prank(admin);
        maatAddressProvider.changeIncentiveController(address(this));

        uint256 amount = formatDecimals(10);

        token.transfer(address(strategy), amount);

        strategy.compound(amount);

        assertEq(strategy.totalIncentives(), amount);
    }
}
