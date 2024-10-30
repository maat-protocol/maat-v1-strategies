// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {AaveStrategyTestSetup} from "./_.AaveStrategy.Setup.sol";
import {AaveV3Strategy} from "../../../contracts/strategies/Aave/AaveV3Strategy.sol";
import {Strategy} from "../../../contracts/Strategy.sol";

contract AaveStrategyDepositTest is AaveStrategyTestSetup {
    uint sharesAfter2Deposits = 178417157;

    function test_deposit() public {
        _deposit(amount, amount);

        assertEq(AaveStrategyContract.balanceOf(maatVault), amount);
        assertEq(token.balanceOf(maatVault), 0);
        assertEq(AaveStrategyContract.totalAssets(), amount);
    }

    function test_deposit_warp() public {
        _deposit(amount, amount);

        vm.warp(block.timestamp + timeWarp);

        _deposit(amount, amount);

        assertEq(
            AaveStrategyContract.balanceOf(maatVault),
            sharesAfter2Deposits
        );

        assertEq(token.balanceOf(maatVault), 0);
    }

    function test_maxDeposit() public view {
        uint maxDeposit = AaveStrategyContract.maxDeposit(maatVault);
        assertEq(maxDeposit, availableToSupply);
    }

    function test_maxDeposit_poolPause() public {
        _setPoolPause();

        uint maxDeposit = AaveStrategyContract.maxDeposit(maatVault);

        assertEq(maxDeposit, 0);
    }

    function test_previewDeposit() public {
        uint shares = AaveStrategyContract.previewDeposit(amount);

        assertEq(shares, amount);
    }

    function test_previewDeposit_warp() public {
        _deposit(amount, amount);

        vm.warp(block.timestamp + timeWarp);

        uint sharesAfterWarp = AaveStrategyContract.previewDeposit(amount);

        assertEq(sharesAfterWarp, sharesAfter2Deposits - amount);
    }

    function test_previewDeposit_big() public {
        uint bigAmount = availableToSupply + 1;

        vm.expectRevert(Strategy.DepositExceedsLimit.selector);

        AaveStrategyContract.previewDeposit(bigAmount);

        amount = availableToSupply;

        uint shares = AaveStrategyContract.previewDeposit(amount);

        assertEq(shares, amount);
    }

    function test_previewDeposit_paused() public {
        _setPoolPause();

        vm.expectRevert(Strategy.DepositExceedsLimit.selector);

        AaveStrategyContract.previewDeposit(amount);
    }
}
