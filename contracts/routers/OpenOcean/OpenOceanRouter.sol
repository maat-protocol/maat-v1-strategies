// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.22;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import {ISwapRouter} from "../../interfaces/ISwapRouter.sol";

import {IOpenOceanCaller} from "./interfaces/IOpenOceanCaller.sol";
import {IOpenOceanExchange} from "./interfaces/IOpenOceanExchange.sol";

contract OpenOceanRouter is ISwapRouter {
    IOpenOceanExchange public OpenOceanExchange;

    string public name = "OpenOceanRouter";

    constructor(address _openOceanExchange) {
        OpenOceanExchange = IOpenOceanExchange(_openOceanExchange);
    }

    function swap(
        address tokenIn,
        uint256 amountIn,
        bytes memory swapData
    ) external {
        IERC20(tokenIn).transferFrom(msg.sender, address(this), amountIn);
        IERC20(tokenIn).approve(address(OpenOceanExchange), amountIn);

        (bool success, ) = address(OpenOceanExchange).call(swapData);

        require(success, "OpenOceanRouter: swap failed");
    }
}
