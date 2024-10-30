// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {AaveStrategyTestSetup} from "./_.AaveStrategy.Setup.sol";

contract AaveStrategyHelpersTest is AaveStrategyTestSetup {
    // function test_GetPool() public view {
    //     address pool = AaveStrategyContract.getPool();
    //     address expectedPool = 0x794a61358D6845594F94dc1DB02A252b5b4814aD;
    //     assertEq(pool, expectedPool);
    // }

    // function test_GetAToken() public view {
    //     address aToken = AaveStrategyContract.getAToken();
    //     address expectedAToken = 0x6ab707Aca953eDAeFBc4fD23bA73294241490620;
    //     assertEq(aToken, expectedAToken);
    // }

    function test_getFromBits() public {
        uint256 input = 0x2c; //101100

        uint256 startFor4 = 0;
        uint256 endFor4 = 2;

        uint256 bits4 = AaveStrategyContract.exposed__getFromBits(
            input,
            startFor4,
            endFor4
        );

        assertEq(bits4, 0x4);

        uint256 startFor5 = 3;
        uint256 endFor5 = 5;

        uint256 bits5 = AaveStrategyContract.exposed__getFromBits(
            input,
            startFor5,
            endFor5
        );

        assertEq(bits5, 0x5);
    }
}
