// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./_StrategyMockImpl.sol";
import "forge-std/console.sol";
import "../../contracts/FeeManager.sol";

contract StrategyTest is StrategyMockImplSetup {
    /* ============ TOTAL ASSETS ============ */

    function test_totalAssets() public {
        uint totalAssets = strategy.totalAssets();
        assertEq(totalAssets, 0);

        uint amount = formatDecimals(100);
        uint shares = strategy.deposit(amount, maatVault);

        uint loss = 1 wei;
        totalAssets = strategy.totalAssets();
        assertEq(totalAssets, amount - loss);

        strategy.redeem(shares, address(this), address(this));

        totalAssets = strategy.totalAssets();
        assertEq(totalAssets, 0);
    }

    /* ============ EARNING ============ */

    function test_earning() public {
        uint amount = formatDecimals(100);
        uint shares = strategy.deposit(amount, address(this));

        skip(100 days);

        uint assets = strategy.redeem(shares, address(this), address(this));

        assertGt(assets, amount);
    }

    /* ============ CONVERTS ============ */

    function test_convertToAssets(uint shares) public view {
        uint assets = strategy.convertToAssets(shares);
        assertEq(assets, shares);
    }

    function test_convertToShares(uint assets) public view {
        uint shares = strategy.convertToShares(assets);
        assertEq(shares, assets);
    }

    /* ============ DEPOSIT ============ */

    function test_previewDeposit() public view {
        uint amount = formatDecimals(100);
        uint previewDeposit = strategy.previewDeposit(amount);

        uint shares = strategy.convertToShares(amount);

        assertEq(previewDeposit, shares);
    }

    function test_deposit() public {
        uint amount = formatDecimals(100);
        uint shares = strategy.deposit(amount, address(this));
        assertEq(
            shares,
            amount,
            "PPS is not 1 on start of the Strategy lifecycle"
        );
        shares = yearnVault.balanceOf(address(strategy));
        assertEq(
            shares,
            96770175,
            "PPS on the moment of 58068067 Polygon block"
        );
    }

    /* ============ MINT ============ */

    function test_maxMint() public view {
        uint strategyMaxMint = strategy.maxMint(address(this));
        uint assets = strategy.convertToAssets(strategyMaxMint);
        // 10_000_000.000000
        // 6_240_155.735019
        uint vaultMaxDeposit = yearnVault.maxDeposit(address(strategy));
        assertEq(assets, vaultMaxDeposit);
    }

    function test_previewMint() public view {
        uint amount = formatDecimals(100);
        uint previewMint = strategy.previewMint(amount);

        uint shares = strategy.convertToShares(amount);

        assertEq(previewMint, shares);
    }

    function test_mint() public {
        uint amount = formatDecimals(100);
        uint previewShares = strategy.previewDeposit(amount);
        uint assets = strategy.mint(previewShares, address(this));

        assertEq(assets, amount);

        uint shares = strategy.balanceOf(address(this));

        assertEq(shares, previewShares);
    }

    /* ============ WITHDRAW ============ */

    function test_maxWithdraw() public {
        strategy.deposit(formatDecimals(100), address(this));
        uint strategyMaxWithdraw = strategy.maxWithdraw(address(this));
    }

    function test_previewWithdraw() public {
        uint amount = formatDecimals(100);
        uint depositShares = strategy.deposit(amount, address(this));
        uint withdrawableAssets = strategy.convertToAssets(depositShares);

        uint withdrawShares = strategy.previewWithdraw(withdrawableAssets);

        assertEq(withdrawShares, depositShares);
    }

    function test_withdraw() public {
        uint initialBalance = token.balanceOf(address(this));
        uint amount = formatDecimals(100);
        uint shares = strategy.deposit(amount, address(this));

        assertEq(strategy.balanceOf(address(this)), shares);
        assertEq(shares, amount);

        shares = strategy.deposit(amount, address(this));

        assertEq(strategy.convertToShares(amount), shares);

        uint assets = strategy.convertToAssets(shares);
        shares = strategy.withdraw(assets, address(this), address(this));

        uint loss = 1 wei;
        assertApproxEqRel(assets, amount, 1e17);
        assertApproxEqRel(token.balanceOf(address(this)), initialBalance, 1e17);
    }

    function test_withdraw_exactAssets() public {
        uint initialBalance = token.balanceOf(address(this));
        uint amount = formatDecimals(100);
        uint shares = strategy.deposit(amount, address(this));

        assertEq(strategy.balanceOf(address(this)), shares);
        assertEq(shares, amount);

        shares = strategy.deposit(amount, address(this));

        assertEq(strategy.convertToShares(amount), shares);

        shares = strategy.withdraw(amount, address(this), address(this));
        uint assets = strategy.convertToAssets(shares);

        assertApproxEqRel(assets, amount, 1e17);
        assertApproxEqRel(token.balanceOf(address(this)), initialBalance, 1e17);
    }

    /* ============ REDEEM ============ */

    function test_maxRedeem() public {
        strategy.deposit(formatDecimals(100), address(this));

        uint maxRedeem = strategy.maxRedeem(address(this));
        uint balance = strategy.balanceOf(address(this));

        assertEq(maxRedeem, balance);
    }

    function test_previewRedeem() public {
        uint amount = formatDecimals(100);
        uint shares = strategy.deposit(amount, address(this));

        uint assets = strategy.previewRedeem(shares);

        uint loss = 1 wei;
        assertEq(assets, amount - loss);
    }

    function test_redeem() public {
        uint initialBalance = token.balanceOf(address(this));
        uint amount = formatDecimals(100);
        uint shares = strategy.deposit(amount, address(this));

        uint loss = 1 wei;

        assertEq(strategy.balanceOf(address(this)), shares);
        assertEq(shares, strategy.convertToShares(amount) - loss);

        uint assets = strategy.redeem(shares, address(this), address(this));

        assertEq(assets, amount - loss);
        assertEq(token.balanceOf(address(this)), initialBalance - loss);
    }

    /* ============ STRATEGY NAME / SYMBOL ============ */

    function test_name() public view {
        string memory name = strategy.name();
        assertEq(name, "MAAT Yearn V3 USDC");
    }

    function test_symbol() public view {
        string memory name = strategy.symbol();
        assertEq(name, "mtUSDC");
    }
}
