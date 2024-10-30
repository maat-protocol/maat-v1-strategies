// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.22;

interface ISwapRouter {
    function name() external view returns (string memory);

    function swap(
        address tokenIn,
        uint256 amountIn,
        bytes memory swapData
    ) external;
}
