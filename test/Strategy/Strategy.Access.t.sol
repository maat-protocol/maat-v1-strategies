// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./_StrategyMockImpl.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract StrategyAccessTest is StrategyMockImplSetup {
    function test_deposit_onlyTokenVault() public {
        uint amount = formatDecimals(100);

        vm.prank(address(0x123));
        vm.expectRevert(Strategy.CallerIsNotTokenVault.selector);

        uint shares = strategy.deposit(amount, address(this));
    }

    function test_mint_onlyTokenVault() public {
        uint amount = formatDecimals(100);
        uint previewShares = strategy.previewDeposit(amount);

        vm.prank(address(0x123));
        vm.expectRevert(Strategy.CallerIsNotTokenVault.selector);

        uint assets = strategy.mint(previewShares, address(this));
    }

    function test_SetFee_RevertIf_CallerIsNotOwner() public {
        vm.prank(address(0x123));
        vm.expectRevert(
            abi.encodeWithSelector(
                Ownable.OwnableUnauthorizedAccount.selector,
                address(0x123)
            )
        );

        strategy.setPerformanceFee(10 ** 7);
    }

    function test_SetFeeTo_RevertIf_CallerIsNotOwner() public {
        vm.prank(address(0x123));
        vm.expectRevert(
            abi.encodeWithSelector(
                Ownable.OwnableUnauthorizedAccount.selector,
                address(0x123)
            )
        );

        strategy.setFeeTo(address(0x123));
    }
}
