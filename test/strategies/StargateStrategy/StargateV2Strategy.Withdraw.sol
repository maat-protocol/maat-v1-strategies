// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.22;

import {StargateV2StrategyTestSetup} from "./_StargateV2Strategy.Setup.sol";

contract StargateV2WithdrawTest is StargateV2StrategyTestSetup {
    function test_withdraw() public {
        uint256 amount = formatDecimals(100);
        uint256 balanceBefore = token.balanceOf(maatVault);
        strategy.deposit(amount, maatVault);
        strategy.withdraw(amount, maatVault, maatVault);

        assertEq(token.balanceOf(maatVault), balanceBefore);
        assertEq(strategy.balanceOf(address(maatVault)), 0);
        assertEq(strategy.totalAssets(), 0);
        assertEq(strategy.totalSupply(), 0);
    }

    function test_withdraw_warp() public {
        uint256 amount = formatDecimals(100);
        uint256 balanceBefore = token.balanceOf(maatVault);

        strategy.deposit(amount, maatVault);
        strategy.withdraw(amount / 2, maatVault, maatVault);

        skip(100 days);

        strategy.withdraw(amount / 4, maatVault, maatVault);
        strategy.withdraw(amount / 4, maatVault, maatVault);
        // stargate pay reward only in incentives, that's why after skip() we still have the same pps == 1
        assertEq(token.balanceOf(maatVault), balanceBefore);
        assertEq(strategy.balanceOf(address(maatVault)), 0);
        assertEq(strategy.totalAssets(), 0);
        assertEq(strategy.totalSupply(), 0);
    }
}
