// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {AaveStrategyTestSetup} from "./_.AaveStrategy.Setup.sol";
import {IPoolAddressesProvider} from "@aave/core-v3/contracts/interfaces/IPoolAddressesProvider.sol";
import {IPool} from "@aave/core-v3/contracts/interfaces/IPool.sol";
import {AaveV3Strategy} from "../../../contracts/strategies/Aave/AaveV3Strategy.sol";

contract AaveStrategyWithdrawTest is AaveStrategyTestSetup {
    uint sharesAfter2Deposits = 178417157;
    uint assetsAfterWarp = 127523113;

    function test_withdraw() public {
        _deposit(amount, amount);

        AaveStrategyContract.withdraw(amount, maatVault, maatVault);

        assertEq(token.balanceOf(maatVault), amount);
        assertEq(AaveStrategyContract.balanceOf(maatVault), 0);
        assertEq(AaveStrategyContract.totalAssets(), 0);
    }

    function test_withdraw_warp() public {
        _deposit(amount, amount);

        vm.warp(block.timestamp + timeWarp);

        AaveStrategyContract.withdraw(assetsAfterWarp, maatVault, maatVault);

        assertEq(token.balanceOf(maatVault), assetsAfterWarp);
        assertEq(AaveStrategyContract.balanceOf(maatVault), 0);
        assertEq(AaveStrategyContract.totalAssets(), 0);
    }

    function test_maxWithdraw() public {
        _deposit(amount, amount);

        uint maxWithdraw = AaveStrategyContract.maxWithdraw(maatVault);

        assertEq(maxWithdraw, amount);
    }

    function test_maxWithdraw_poolPause() public {
        _deposit(amount, amount);

        _setPoolPause();

        uint maxWithdraw = AaveStrategyContract.maxWithdraw(maatVault);

        assertEq(maxWithdraw, 0);
    }

    // function test_maxWithdraw_lowLiquidity() public {
    //     address daiHolder = address(12345);

    //     uint amount = 1e13;

    //     _deposit(amount, amount);

    //     deal(address(DAI), daiHolder, UINT256_MAX);

    //     vm.startPrank(daiHolder);

    //     IPoolAddressesProvider addressesProvider = AaveStrategyContract
    //         .PoolAddressesProvider();

    //     address pool = addressesProvider.getPool();

    //     DAI.approve(pool, UINT256_MAX);

    //     IPool(pool).supply(address(DAI), 2e24, daiHolder, 0);

    //     uint availableLiquidity = AaveStrategyContract
    //         .exposed_getAvaliableLiquidity();

    //     console.log(availableLiquidity);

    //     IPool(pool).borrow(address(token), 2e12, 2, 0, daiHolder);

    //     uint availableLiquidity2 = AaveStrategyContract
    //         .exposed_getAvaliableLiquidity();

    //     console.log(availableLiquidity2);

    //     vm.startPrank(maatVault);

    //     uint maxWithdraw = AaveStrategyContract.maxWithdraw(maatVault);

    //     console.log(maxWithdraw);
    // }

    function test_previewWithdraw() public {
        _deposit(amount, amount);

        uint shares = AaveStrategyContract.previewWithdraw(amount);

        assertEq(shares, amount);
    }

    function test_previewWithdraw_warp() public {
        _deposit(amount, amount);

        vm.warp(block.timestamp + timeWarp);

        uint sharesAfterWarp = AaveStrategyContract.previewWithdraw(
            assetsAfterWarp
        );

        assertEq(sharesAfterWarp, amount);
    }

    function test_previewWithdraw_big() public {
        _deposit(amount, amount);

        uint bigAmount = 1e18;

        vm.expectRevert(AaveV3Strategy.NotEnoughAvailableLiquidity.selector);

        AaveStrategyContract.previewWithdraw(bigAmount);
    }

    function test_previewDeposit_paused() public {
        _deposit(amount, amount);

        _setPoolPause();

        vm.expectRevert(AaveV3Strategy.NotEnoughAvailableLiquidity.selector);

        AaveStrategyContract.previewWithdraw(amount);
    }
}
