// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.22;

import {StargateV2StrategyTestSetup} from "./_StargateV2Strategy.Setup.sol";

contract StargateV2ViewTest is StargateV2StrategyTestSetup {
    uint256 deposited;

    function _afterSetUp() internal override {
        deposited = formatDecimals(100);
        super._afterSetUp();
        strategy.deposit(deposited, maatVault);

        skip(100 days);
    }

    function test_maxDeposit() public view {
        uint256 maxDeposit = strategy.maxDeposit(maatVault);

        assertEq(maxDeposit, type(uint256).max);
    }

    function test_previewDeposit() public view {
        uint256 assets = formatDecimals(100);
        uint256 shares = strategy.previewDeposit(assets);

        assertEq(shares, assets);
        assertEq(strategy.convertToAssets(shares), assets);
        assertEq(strategy.convertToShares(assets), shares);
    }

    function test_maxMint() public view {
        uint256 maxMint = strategy.maxMint(maatVault);

        assertEq(
            maxMint,
            strategy.convertToShares(strategy.maxDeposit(maatVault))
        );
    }

    function test_previewMint() public view {
        uint256 amount = formatDecimals(100);

        uint256 shares = strategy.convertToShares(amount);
        uint256 assets = strategy.previewMint(shares);

        assertEq(shares, assets);
        assertEq(strategy.convertToAssets(shares), assets);
        assertEq(strategy.convertToShares(assets), shares);
    }

    function test_maxWithdraw() public view {
        uint256 maxWithdraw = strategy.maxWithdraw(maatVault);

        assertEq(maxWithdraw, deposited);
    }

    function test_previewWithdraw() public view {
        uint256 shares = strategy.previewWithdraw(deposited);

        assertEq(shares, deposited);
        assertEq(strategy.convertToAssets(shares), deposited);
        assertEq(strategy.convertToShares(deposited), shares);
    }

    function test_maxRedeem() public view {
        uint256 maxRedeem = strategy.maxRedeem(maatVault);

        assertEq(maxRedeem, strategy.convertToShares(deposited));
    }

    function test_previewRedeem() public view {
        uint256 shares = strategy.convertToShares(deposited);

        uint256 assets = strategy.previewRedeem(shares);

        assertEq(assets, deposited);
    }
}
