// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {BaseTest} from "../../utils.sol";
import {YearnV3Strategy} from "../../../contracts/strategies/Yearn/YearnV3Strategy.sol";
import {Strategy} from "../../../contracts/Strategy.sol";
import {IStrategy} from "../../../contracts/interfaces/IStrategy.sol";
import {IERC4626} from "@openzeppelin/contracts/interfaces/IERC4626.sol";
import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {StrategyTestSetup} from "../../Strategy/_Strategy.Setup.sol";

contract YearnStrategyTest is StrategyTestSetup {
    uint32 chainId;
    uint256 blockNumber;

    address feeTo = address(0xbeefbeffbeefbeefbeffbeefbefefbeffbeef);
    uint fee = 10 ** 7;

    IERC4626 yearnVault;

    constructor() {
        chainId = 137;
        blockNumber = 58068067;

        token = IERC20Metadata(address(constants.getAddress("polygon.usdc")));

        yearnVault = IERC4626(constants.getAddress("polygon.yearnUSDCVault"));
    }

    function setUp() public virtual override {
        fork(chainId, blockNumber);
        super.setUp();

        strategyParams = IStrategy.StrategyParams(
            chainId,
            "Yearn",
            3,
            address(token),
            address(yearnVault)
        );

        strategy = _deploy_YearnV3Strategy(
            strategyParams,
            address(maatAddressProvider),
            feeTo,
            fee
        );

        vm.prank(admin);
        maatAddressProvider.addStrategy(address(strategy));

        vm.label(address(strategy), "Strategy");

        _prepareTokens();
    }

    // Added to pass constructor require for same token as maatVault
    function asset() public view override returns (address) {
        return address(token);
    }

    /* ============ TOTAL ASSETS ============ */

    function test_totalAssets() public {
        uint totalAssets = strategy.totalAssets();
        assertEq(totalAssets, 0);

        uint amount = formatDecimals(100);
        uint shares = strategy.deposit(amount, address(this));

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

    function test_maxDeposit() public view {
        // strategy.deposit(formatDecimals(100), address(this));

        uint strategyMaxDeposit = strategy.maxDeposit(address(this));
        // 10_000_000.000000
        // 6_240_155.735019
        uint vaultMaxDeposit = yearnVault.maxDeposit(address(strategy));

        assertEq(strategyMaxDeposit, vaultMaxDeposit);
    }

    function test_previewDeposit() public view {
        uint amount = formatDecimals(100);
        uint previewDeposit = strategy.previewDeposit(amount);

        uint shares = strategy.convertToShares(amount);

        assertEq(previewDeposit, shares);
    }

    function test_deposit() public {
        vm.startPrank(maatVault);
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
        uint vaultMaxWithdraw = yearnVault.maxWithdraw(address(strategy));

        assertEq(strategyMaxWithdraw, vaultMaxWithdraw);
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

        uint assets = strategy.convertToAssets(shares);
        shares = strategy.withdraw(assets, address(this), address(this));

        uint loss = 1 wei;
        assertEq(assets, amount - loss);
        assertEq(token.balanceOf(address(this)), initialBalance - loss);
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

        uint assets = strategy.redeem(shares, address(this), address(this));

        uint loss = 1 wei;
        assertEq(assets, amount - loss);
        assertEq(token.balanceOf(address(this)), initialBalance - loss);
    }
}
