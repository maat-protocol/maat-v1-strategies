// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.22;

import {OpenOceanRouter} from "../../../contracts/routers/OpenOcean/OpenOceanRouter.sol";

import {OpenOceanRouterTestSetup} from "./_OpenOceanRouter.Setup.sol";
import "forge-std/console.sol";

contract OpenOceanRouterTestSwap is OpenOceanRouterTestSetup {
    bytes swapData;

    constructor() {
        swapData = constants.swapData();
    }

    function test_swap() public {
        uint256 amountToSwap = 1e6;
        deal(address(USDT), alice, amountToSwap);

        vm.startPrank(alice);
        USDT.approve(address(openOceanRouter), amountToSwap);

        openOceanRouter.swap(address(USDT), amountToSwap, swapData);
    }
}
