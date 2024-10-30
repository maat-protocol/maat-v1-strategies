// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {AaveStrategyTestSetup} from "./_.AaveStrategy.Setup.sol";
import {Strategy} from "../../../contracts/Strategy.sol";

contract AaveStrategyMintTest is AaveStrategyTestSetup {
    uint sharesAfter2Deposits = 178417157;

    function test_mint() public {
        uint amount = 1e8;

        _mint(amount, amount);

        assertEq(AaveStrategyContract.balanceOf(maatVault), amount);
        assertEq(token.balanceOf(maatVault), 0);
        assertEq(AaveStrategyContract.totalAssets(), amount);
    }

    function test_mint_warp() public {
        uint amount = 1e8;

        _mint(amount, amount);

        vm.warp(block.timestamp + timeWarp);

        _mint(amount, sharesAfter2Deposits - amount);

        assertEq(
            AaveStrategyContract.balanceOf(maatVault),
            sharesAfter2Deposits
        );

        assertApproxEqAbs(token.balanceOf(maatVault), 0, 20);
    }

    function test_maxMint() public view {
        uint maxMint = AaveStrategyContract.maxMint(maatVault);
        assertEq(maxMint, availableToSupply);
    }

    function test_maxMint_poolPause() public {
        _setPoolPause();

        uint maxMint = AaveStrategyContract.maxMint(maatVault);

        assertEq(maxMint, 0);
    }

    function test_previewMint() public {
        uint amount = 1e8;

        uint assets = AaveStrategyContract.previewMint(amount);

        assertEq(assets, amount);
    }

    function test_previewMint_warp() public {
        uint amount = 1e8;

        _mint(amount, amount);

        vm.warp(block.timestamp + timeWarp);

        uint assetsAfterWarp = AaveStrategyContract.previewMint(
            sharesAfter2Deposits - amount
        );

        assertApproxEqAbs(assetsAfterWarp, amount, 20);
    }

    function test_previewMint_big() public {
        uint bigAmount = availableToSupply + 1;

        uint bigShares = AaveStrategyContract.convertToShares(bigAmount);

        vm.expectRevert(Strategy.DepositExceedsLimit.selector);

        AaveStrategyContract.previewMint(bigShares);

        uint amount = availableToSupply;

        uint assets = AaveStrategyContract.previewMint(
            AaveStrategyContract.convertToShares(amount)
        );

        assertEq(assets, amount);
    }

    function test_previewMint_paused() public {
        uint amount = 1e8;
        _setPoolPause();

        vm.expectRevert(Strategy.DepositExceedsLimit.selector);

        AaveStrategyContract.previewMint(amount);
    }
}
