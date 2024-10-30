// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.22;

import {HarvestV2StrategyTestSetup} from "./_HarvestV2Strategy.Setup.sol";

contract HarvestV2DepositTest is HarvestV2StrategyTestSetup {
    function test_deposit() public {
        uint256 amount = formatDecimals(100);
        uint256 balanceBefore = token.balanceOf(maatVault);
        vm.prank(maatVault);
        strategy.deposit(amount, maatVault);

        assertEq(strategy.balanceOf(address(maatVault)), amount);
        assertEq(token.balanceOf(maatVault), balanceBefore - amount);
        assertEq(strategy.totalAssets(), amount - 1);
        assertEq(strategy.totalSupply(), amount);
    }

    function test_deposit_warp() public {
        uint256 amount = formatDecimals(100);
        vm.startPrank(maatVault);
        uint256 sharesFirst = strategy.deposit(amount, maatVault);

        skip(100 days);

        vm.stopPrank();
        doHardWork();
        vm.startPrank(maatVault);

        uint256 sharesSecond = strategy.deposit(amount, maatVault);
        assertGt(sharesFirst, sharesSecond);
    }
}
