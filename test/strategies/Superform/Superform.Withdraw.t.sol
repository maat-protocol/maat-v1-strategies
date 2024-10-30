// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {SuperformStrategyTestSetup} from "./_.SuperformStrategy.Setup.t.sol";

contract SuperformWithdrawTest is SuperformStrategyTestSetup {
    uint maxExpectedWithdrawLoss = 1 wei;

    uint withdrawAmount = 100e6;

    function _afterSetUp() internal override {
        token.approve(address(superformStrategy), withdrawAmount);

        superformStrategy.deposit(withdrawAmount, address(this));
    }

    function test_Withdraw_MaxAmount() public view {
        uint maxWithdraw = superformStrategy.maxWithdraw(address(this));
        uint expectedLoss = 1 wei;
        assertEq(maxWithdraw, withdrawAmount - expectedLoss);
    }

    function testFuzz_Withdraw_ReturnsTokens(
        uint _withdrawAmount
    )
        public
        tokenBalanceMustIncreaseApprox(
            address(this),
            _withdrawAmount,
            maxExpectedWithdrawLoss
        )
    {
        /* ======== ASSUME ======== */

        vm.assume(_withdrawAmount <= withdrawAmount - maxExpectedWithdrawLoss);
        vm.assume(_withdrawAmount > 0);

        /* ======== FUZZ ======== */

        superformStrategy.withdraw(
            _withdrawAmount,
            address(this),
            address(this)
        );
    }

    function test_Withdraw_TakesRepresentations()
        public
        tokenBalanceMustIncreaseApprox(
            address(this),
            withdrawAmount,
            maxExpectedWithdrawLoss
        )
    {
        uint balanceBefore = superPositions.balanceOf(
            address(superformStrategy),
            superformId
        );

        assertGt(
            balanceBefore,
            withdrawAmount / 2, // Just a random non 0 value
            "There MUST be some representations before withdraw"
        );

        superformStrategy.withdraw(
            withdrawAmount - 1 wei,
            address(this),
            address(this)
        );

        uint shares = superPositions.balanceOf(
            address(superformStrategy),
            superformId
        );

        assertEq(shares, 0, "There MUST be no representations after withdraw");
    }
}
