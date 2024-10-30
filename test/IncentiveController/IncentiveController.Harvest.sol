// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.22;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import {IncentiveControllerTestSetup} from "./_IncentiveController.Setup.sol";
import {IStrategyWithIncentives} from "../../contracts/interfaces/IStrategyWithIncentives.sol";

import {console} from "forge-std/console.sol";

contract IncentiveControllerHarvestTest is IncentiveControllerTestSetup {
    bytes swapData;

    constructor() {
        swapData = constants.swapDataFromSTGToUSDCOnArbitrum();
    }

    function test_harvestAndCompound() public {
        assertEq(
            incentiveController.isSupportedRouter(address(openOceanRouter)),
            true
        );

        uint256 amount = formatDecimals(100);
        strategy.deposit(amount, maatVault);

        skip(100 days);

        IStrategyWithIncentives strategyWithIncentives = IStrategyWithIncentives(
                address(strategy)
            );

        bytes[] memory swapsData = new bytes[](1);
        swapsData[0] = swapData;

        vm.prank(compounder);
        incentiveController.harvestAndCompound(
            address(openOceanRouter),
            strategyWithIncentives,
            swapsData
        );

        assertGt(strategyWithIncentives.totalIncentives(), 0);

        uint256 shares = strategy.deposit(amount, maatVault);

        assertNotEq(shares, amount);
    }
}
