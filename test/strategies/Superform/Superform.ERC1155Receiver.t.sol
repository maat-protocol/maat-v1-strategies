// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {SuperformStrategyTestSetup} from "./_.SuperformStrategy.Setup.t.sol";
import {console} from "forge-std/console.sol";

contract SuperformWithdrawTest is SuperformStrategyTestSetup {
    function test_onERC1155Received() public view {
        bytes memory data = abi.encode(address(superformStrategy));

        bytes4 result = superformStrategy.onERC1155Received(
            address(superformStrategy),
            address(this),
            0,
            0,
            data
        );

        assertEq(result, superformStrategy.onERC1155Received.selector);
    }
}
