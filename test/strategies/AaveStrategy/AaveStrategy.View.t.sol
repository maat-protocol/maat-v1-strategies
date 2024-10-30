// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {AaveStrategyTestSetup} from "./_.AaveStrategy.Setup.sol";

contract AaveStrategyViewTest is AaveStrategyTestSetup {
    function test_asset() public view {
        assertEq(AaveStrategyContract.asset(), address(token));
    }
}
