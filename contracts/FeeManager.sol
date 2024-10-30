// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import {ERC165Checker} from "@openzeppelin/contracts/utils/introspection/ERC165Checker.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

abstract contract FeeManager is Ownable {
    error InvalidFeeInput();
    error ZeroFeeToAddress();

    uint public performanceFee;
    uint public constant feePrecision = 10 ** 8;

    uint constant maxPossibleFee = 5 * 10 ** 7;

    address public feeTo;

    constructor(uint fee, address _feeTo) {
        feeTo = _feeTo;
        performanceFee = fee;
    }

    function _calculateFee(uint amount) internal view returns (uint) {
        return (amount * performanceFee) / feePrecision;
    }

    /* ========== ADMIN ========== */
    function setPerformanceFee(uint fee) external onlyOwner {
        _validateFee(fee);

        performanceFee = fee;
    }

    function setFeeTo(address _feeTo) external onlyOwner {
        if (_feeTo == address(0)) revert ZeroFeeToAddress();

        feeTo = _feeTo;
    }

    /* ========== VALIDATION ========== */

    function _validateFee(uint fee) internal pure {
        if (fee > maxPossibleFee) revert InvalidFeeInput();
    }
}
