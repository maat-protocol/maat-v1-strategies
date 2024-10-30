// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.22;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import {IncentiveControllerTestSetup} from "./_IncentiveController.Setup.sol";
import {IStrategyWithIncentives} from "../../contracts/interfaces/IStrategyWithIncentives.sol";

import {console} from "forge-std/console.sol";

contract IncentiveControllerAdminTest is IncentiveControllerTestSetup {
    function test_changeCompounder() public {
        assertEq(incentiveController.compounder(), compounder);

        vm.prank(incentiveControllerAdmin);

        address newCompounder = address(0x1);
        incentiveController.changeCompounder(newCompounder);

        assertEq(incentiveController.compounder(), newCompounder);
    }

    function test_addSwapRouter() public {
        assertEq(
            incentiveController.isSupportedRouter(address(openOceanRouter)),
            true
        );

        vm.prank(incentiveControllerAdmin);

        address newSwapRouter = address(0x1);
        incentiveController.addSwapRouter(newSwapRouter);

        assertEq(incentiveController.isSupportedRouter(newSwapRouter), true);
    }

    function test_removeSwapRouter() public {
        assertEq(
            incentiveController.isSupportedRouter(address(openOceanRouter)),
            true
        );

        vm.prank(incentiveControllerAdmin);

        incentiveController.removeSwapRouter(address(openOceanRouter));

        assertEq(
            incentiveController.isSupportedRouter(address(openOceanRouter)),
            false
        );
    }
}
