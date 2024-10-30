// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {SuperformStrategyTestSetup} from "./_.SuperformStrategy.Setup.t.sol";

contract SuperformDepositTest is SuperformStrategyTestSetup {
    uint depositAmount = 100e6;

    function testFuzz_Deposit_TakesTokens(
        uint _depositAmount
    ) public tokenBalanceMustDecrease(address(this), _depositAmount) {
        /* ======== ASSUME ======== */

        vm.assume(_depositAmount < 1_000_000e6);
        vm.assume(_depositAmount > 1);

        /* ======== FUZZ ======== */

        superformStrategy.deposit(_depositAmount, address(this));
    }

    function test_Deposit_ReturnsShares() public {
        uint balanceBefore = superPositions.balanceOf(
            address(this),
            superformId
        );

        assertEq(
            balanceBefore,
            0,
            "There MUST be no representations before deposit"
        );

        uint previewShares = protocolVault.previewDepositTo(depositAmount);

        superformStrategy.deposit(depositAmount, address(this));

        uint shares = superPositions.balanceOf(
            address(superformStrategy),
            superformId
        );

        assertEq(
            shares,
            previewShares,
            "There MUST be representations depositAmount equal to deposit preview result"
        );
    }
}
