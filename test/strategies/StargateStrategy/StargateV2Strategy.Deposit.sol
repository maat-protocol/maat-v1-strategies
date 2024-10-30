// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.22;

import {StargateV2StrategyTestSetup} from "./_StargateV2Strategy.Setup.sol";

contract StargateV2DepositTest is StargateV2StrategyTestSetup {
    function test_deposit() public {
        uint256 amount = formatDecimals(100);
        uint256 balanceBefore = token.balanceOf(maatVault);
        vm.prank(maatVault);
        strategy.deposit(amount, maatVault);

        assertEq(strategy.balanceOf(address(maatVault)), amount);
        assertEq(token.balanceOf(maatVault), balanceBefore - amount);
        assertEq(strategy.totalAssets(), amount);
        assertEq(strategy.totalSupply(), amount);
    }

    function test_deposit_warp() public {
        uint256 amount = formatDecimals(100);
        vm.startPrank(maatVault);
        strategy.deposit(amount, maatVault);

        skip(100 days);

        strategy.deposit(amount, maatVault);
        // stargate pay reward only in incentives, that's why after skip() we still have the same pps == 1
        assertEq(strategy.balanceOf(address(maatVault)), amount * 2);
        assertEq(strategy.totalAssets(), amount * 2);
        assertEq(strategy.totalSupply(), amount * 2);
    }
}
