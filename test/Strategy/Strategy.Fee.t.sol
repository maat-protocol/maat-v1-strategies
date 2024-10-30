// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./_StrategyMockImpl.sol";
import "forge-std/console.sol";
import "../../contracts/FeeManager.sol";

contract StrategyTest is StrategyMockImplSetup {
    function test_FeeAccruals_AfterDeposit() public {
        uint amount = formatDecimals(100);

        strategy.deposit(amount, address(this));

        uint firstTotalSupply = strategy.totalSupply();

        assertEq(strategy.balanceOf(feeTo), 0);

        uint assetsBefore = strategy.totalAssets();

        skip(100 days);

        uint yield = strategy.totalAssets() - assetsBefore;
        uint yieldInShares = strategy.convertToShares(
            (yield * 10 ** 7) / 10 ** 8
        );
        uint predictedSecondTotalSupply = firstTotalSupply +
            strategy.convertToShares(amount);
        strategy.deposit(amount, address(this));

        assertEq(strategy.balanceOf(feeTo), yieldInShares);
        assertGt(strategy.totalSupply(), predictedSecondTotalSupply);
    }

    function testFuzzing_FeeAccruals_AfterWithdrawal(uint amount) public {
        vm.assume(amount < strategy.maxDeposit(address(this)));
        vm.assume(amount > 10 ** 5);

        strategy.deposit(amount, address(this));

        assertEq(strategy.balanceOf(feeTo), 0);

        skip(100 days);

        strategy.redeem(
            strategy.balanceOf(address(this)),
            address(this),
            address(this)
        );
        assertGt(strategy.balanceOf(feeTo), 0);
    }

    function test_FeeWithdrawal() public {
        uint amount = formatDecimals(100);

        strategy.deposit(amount, address(this));

        skip(100 days);

        strategy.deposit(amount, address(this));

        uint assetsBefore = token.balanceOf(address(this));

        strategy.redeem(
            strategy.balanceOf(address(this)),
            address(this),
            address(this)
        );

        uint assetsAfter = token.balanceOf(address(this));
        assertGt(assetsAfter, assetsBefore);

        uint assetsFeesBefore = token.balanceOf(feeTo);

        vm.startPrank(feeTo);
        strategy.redeem(strategy.balanceOf(feeTo), feeTo, feeTo);

        uint assetsFeesAfter = token.balanceOf(feeTo);
        assertGt(assetsFeesAfter, assetsFeesBefore);
    }

    function test_SetPerformanceFee() public {
        uint fee = 10 ** 7;
        strategy.setPerformanceFee(fee);

        assertEq(strategy.performanceFee(), fee);
    }

    function test_SetPerformanceFee_RevertIf_GreaterThanOne() public {
        vm.expectRevert(FeeManager.InvalidFeeInput.selector);
        strategy.setPerformanceFee(10 ** 8 + 1);
    }

    function test_SetFeeTo() public {
        address feeTo = address(0x123);
        strategy.setFeeTo(feeTo);

        assertEq(strategy.feeTo(), feeTo);
    }

    function test_SetFeeTo_RevertIf_ZeroAddress() public {
        vm.expectRevert(FeeManager.ZeroFeeToAddress.selector);
        strategy.setFeeTo(address(0));
    }
}
