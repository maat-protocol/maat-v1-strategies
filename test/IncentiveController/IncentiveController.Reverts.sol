// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.22;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

import {IncentiveControllerTestSetup, IncentiveController} from "./_IncentiveController.Setup.sol";
import {IStrategyWithIncentives} from "../../contracts/interfaces/IStrategyWithIncentives.sol";

import {console} from "forge-std/console.sol";

contract IncentiveControllerRevertsTest is IncentiveControllerTestSetup {
    bytes swapData;

    constructor() {
        swapData = constants.swapDataFromSTGToUSDCOnArbitrum();
    }

    function test_changeCompounder_onlyOwner() public {
        assertEq(incentiveController.compounder(), compounder);

        address newCompounder = address(0x1);

        vm.expectRevert(
            abi.encodeWithSelector(
                Ownable.OwnableUnauthorizedAccount.selector,
                alice
            )
        );
        vm.prank(alice);

        incentiveController.changeCompounder(newCompounder);
    }

    function test_addSwapRouter_onlyOwner() public {
        assertEq(
            incentiveController.isSupportedRouter(address(openOceanRouter)),
            true
        );

        address newSwapRouter = address(0x1);

        vm.expectRevert(
            abi.encodeWithSelector(
                Ownable.OwnableUnauthorizedAccount.selector,
                alice
            )
        );
        vm.prank(alice);

        incentiveController.addSwapRouter(newSwapRouter);
    }

    function test_removeSwapRouter_onlyOwner() public {
        assertEq(
            incentiveController.isSupportedRouter(address(openOceanRouter)),
            true
        );

        vm.expectRevert(
            abi.encodeWithSelector(
                Ownable.OwnableUnauthorizedAccount.selector,
                alice
            )
        );
        vm.prank(alice);

        incentiveController.removeSwapRouter(address(openOceanRouter));
    }

    function test_harvestAndCompound_onlyCompounder() public {
        IStrategyWithIncentives strategyWithIncentives = IStrategyWithIncentives(
                address(strategy)
            );

        bytes[] memory swapsData = new bytes[](1);
        swapsData[0] = swapData;

        vm.expectRevert(
            abi.encodeWithSelector(IncentiveController.OnlyCompounder.selector)
        );
        vm.prank(alice);
        incentiveController.harvestAndCompound(
            address(openOceanRouter),
            strategyWithIncentives,
            swapsData
        );
    }

    function test_harvestAndCompound_onlySupportedRouter() public {
        IStrategyWithIncentives strategyWithIncentives = IStrategyWithIncentives(
                address(strategy)
            );

        bytes[] memory swapsData = new bytes[](1);
        swapsData[0] = swapData;

        vm.expectRevert(
            abi.encodeWithSelector(
                IncentiveController.OnlySupportedRouter.selector
            )
        );
        vm.prank(compounder);
        incentiveController.harvestAndCompound(
            address(0x1),
            strategyWithIncentives,
            swapsData
        );
    }

    function test_harvestAndCompound_swapDataLengthMismatch() public {
        uint256 amount = formatDecimals(100);
        strategy.deposit(amount, maatVault);

        skip(100 days);

        IStrategyWithIncentives strategyWithIncentives = IStrategyWithIncentives(
                address(strategy)
            );

        bytes[] memory swapsData = new bytes[](3);
        swapsData[0] = swapData;
        swapsData[1] = swapData;
        swapsData[2] = swapData;

        vm.expectRevert(
            abi.encodeWithSelector(
                IncentiveController.SwapDataLengthMismatch.selector,
                uint8(1),
                uint8(3)
            )
        );
        vm.prank(compounder);
        incentiveController.harvestAndCompound(
            address(openOceanRouter),
            strategyWithIncentives,
            swapsData
        );
    }

    function test_deploy_initialOwnerNotZero() public {
        vm.expectRevert(
            abi.encodeWithSelector(
                Ownable.OwnableInvalidOwner.selector,
                address(0)
            )
        );
        new IncentiveController(address(0), compounder);
    }
}
