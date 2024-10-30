// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.20;

import {IStrategy} from "../interfaces/IStrategy.sol";

library StrategyIdLib {
    function getStrategyId(
        IStrategy.StrategyParams memory params
    ) internal pure returns (bytes32 strategyId) {
        return
            keccak256(
                abi.encode(
                    params.chainId,
                    params.protocol,
                    params.protocolVersion,
                    params.token,
                    params.protocolVault
                )
            );
    }
}
