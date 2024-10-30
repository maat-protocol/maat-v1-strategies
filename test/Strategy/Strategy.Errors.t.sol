// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./_StrategyMockImpl.sol";

contract StrategyTest is StrategyMockImplSetup {
    function test_deposit_errors() public {
        vm.expectRevert(Strategy.ZeroAssets.selector);
        strategy.deposit(0, address(this));

        uint amount = formatDecimals(100);
        vm.expectRevert(
            abi.encodeWithSelector(Strategy.ZeroAddress.selector, "receiver")
        );
        strategy.deposit(amount, address(0));

        uint limit = strategy.maxDeposit(address(this));
        vm.expectRevert(Strategy.DepositExceedsLimit.selector);
        strategy.deposit(limit + 1 wei, address(this));

        // Should not be reverted
        strategy.deposit(limit, address(this));
    }

    function test_mint_errors() public {
        vm.expectRevert(Strategy.ZeroAssets.selector);
        strategy.mint(0, address(this));

        uint amount = formatDecimals(100);
        vm.expectRevert(
            abi.encodeWithSelector(Strategy.ZeroAddress.selector, "receiver")
        );
        strategy.mint(amount, address(0));

        uint limit = strategy.maxMint(address(this));
        vm.expectRevert(Strategy.DepositExceedsLimit.selector);
        strategy.mint(limit + 1 wei, address(this));

        // Should not be reverted
        strategy.mint(limit, address(this));
    }

    function test_withdraw_errors() public {
        uint amount = formatDecimals(100);
        uint shares = strategy.deposit(amount, address(this));
        uint assets = strategy.convertToAssets(shares);

        vm.expectRevert(Strategy.ZeroAssets.selector);
        strategy.withdraw(0, address(this), address(this));

        vm.expectRevert(
            abi.encodeWithSelector(Strategy.ZeroAddress.selector, "receiver")
        );
        strategy.withdraw(assets, address(0), address(this));

        vm.expectRevert(
            abi.encodeWithSelector(Strategy.ZeroAddress.selector, "owner")
        );
        strategy.withdraw(assets, address(this), address(0));
    }

    function test_redeem_errors() public {
        uint amount = formatDecimals(100);
        uint shares = strategy.deposit(amount, address(this));

        vm.expectRevert(Strategy.ZeroAssets.selector);
        strategy.redeem(0, address(this), address(this));

        vm.expectRevert(
            abi.encodeWithSelector(Strategy.ZeroAddress.selector, "receiver")
        );
        strategy.redeem(shares, address(0), address(this));

        vm.expectRevert(
            abi.encodeWithSelector(Strategy.ZeroAddress.selector, "owner")
        );
        strategy.withdraw(shares, address(this), address(0));
    }

    function test_internalDeposit() public {
        // address maatVault = address(this);
        // StrategyImplementationHarness strategyHarness = new StrategyImplementationHarness(
        //         strategyParams,
        //         maatVault
        //     );
        // token.approve(address(strategyHarness), token.balanceOf(address(this)));
        // uint assets = formatDecimals(100);
        // uint shares = strategyHarness.convertToShares(assets);
        // strategyHarness.exposed_deposit(address(this), assets, shares);
        // vm.expectRevert(Strategy.ZeroAssets.selector);
        // strategyHarness.exposed_deposit(address(this), 0, shares);
        // vm.expectRevert(Strategy.ZeroShares.selector);
        // strategyHarness.exposed_deposit(address(this), assets, 0);
        // vm.expectRevert(Strategy.ZeroAssets.selector);
        // strategyHarness.exposed_deposit(address(this), 0, 0);
        // vm.expectRevert(Strategy.InvalidAssetsInput.selector);
        // strategyHarness.exposed_deposit(address(this), 100e6, 50e10);
    }
}
