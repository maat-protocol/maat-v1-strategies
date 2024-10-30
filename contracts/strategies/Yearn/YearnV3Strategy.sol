// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Strategy} from "../../Strategy.sol";
import {IERC4626} from "@openzeppelin/contracts/interfaces/IERC4626.sol";

contract YearnV3Strategy is Strategy {
    IERC4626 internal immutable vault;

    constructor(
        StrategyParams memory _strategyParams,
        address _maatAddressProvider,
        address _feeTo,
        uint fee
    ) Strategy(_strategyParams, _maatAddressProvider, _feeTo, fee) {
        vault = IERC4626(_strategyParams.protocolVault);
    }

    function totalAssets()
        public
        view
        override
        returns (uint256 totalManagedAssets)
    {
        return vault.maxWithdraw(address(this));
    }

    function maxDeposit(
        address
    ) public view override returns (uint256 maxAssets) {
        return vault.maxDeposit(address(this));
    }

    function _beforeMint(address, uint assets, uint) internal override {
        token.approve(address(vault), assets);
        // Stores yTokens on Strategy
        // Sends mtTokens to maatVault
        vault.deposit(assets, address(this));
    }

    function _afterBurn(address, address, uint assets, uint) internal override {
        vault.withdraw(assets, msg.sender, address(this));
    }
}
