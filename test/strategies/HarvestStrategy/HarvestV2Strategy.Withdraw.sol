// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.22;

import {HarvestV2StrategyTestSetup} from "./_HarvestV2Strategy.Setup.sol";

import {console2} from "forge-std/console2.sol";

contract HarvestV2WithdrawTest is HarvestV2StrategyTestSetup {
    function test_withdraw() public {
        uint256 amount = formatDecimals(100);
        strategy.deposit(amount, maatVault);

        strategy.withdraw(
            strategy.maxWithdraw(address(maatVault)),
            maatVault,
            maatVault
        );

        // assertEq(token.balanceOf(maatVault), balanceBefore);
        // assertEq(strategy.balanceOf(address(maatVault)), 0);
        // assertEq(strategy.totalAssets(), 0);
        // assertEq(strategy.totalSupply(), 0);
    }

    function test_withdraw_warp() public {
        uint256 amount = formatDecimals(100);
        uint256 balanceBefore = token.balanceOf(maatVault);
        vm.startPrank(maatVault);

        strategy.deposit(amount, maatVault);
        strategy.withdraw(amount / 2, maatVault, maatVault);

        vm.stopPrank();
        doHardWork();
        vm.startPrank(maatVault);

        strategy.withdraw(amount / 4, maatVault, maatVault);
        strategy.withdraw(amount / 4, maatVault, maatVault);

        // console2.log("balanceBefore", balanceBefore);
        // console2.log("balanceOf", token.balanceOf(address(maatVault)));
        // assertEq(token.balanceOf(maatVault), balanceBefore);
        // assertEq(strategy.balanceOf(address(maatVault)), 0);
        // assertEq(strategy.totalAssets(), 0);
        // assertEq(strategy.totalSupply(), 0);
    }
}
