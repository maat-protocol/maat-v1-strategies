// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.22;

import {StargateV2Strategy} from "../../../contracts/strategies/Stargate/StargateV2Strategy.sol";

import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {IStrategy} from "../../../contracts/interfaces/IStrategy.sol";

import {StrategyTestSetup} from "../../Strategy/_Strategy.Setup.sol";
import {IMultiRewarder} from "contracts/strategies/Stargate/interfaces/IMultiRewarder.sol";
import {IStargateStaking} from "contracts/strategies/Stargate/interfaces/IStaking.sol";

contract StargateV2StrategyTestSetup is StrategyTestSetup {
    address stargatePoolUSDC;
    IStargateStaking stargateStaking;
    IMultiRewarder stargateMultiRewarder;

    address feeTo = address(0xbeefbeffbeefbeefbeffbeefbefefbeffbeef);
    uint fee = 10 ** 7;

    uint32 chainId;
    uint256 blockNumber;

    address wrappedNativeToken;

    constructor() {
        string memory _strategyName = "arbitrum";

        chainId = uint32(constants.defaultForkChainId());
        blockNumber = constants.defaultForkBlockNumber();

        USDC = IERC20Metadata(
            constants.getAddress(string.concat(_strategyName, ".usdc"))
        );

        stargatePoolUSDC = constants.getAddress(
            string.concat(_strategyName, ".stargatePoolUSDC")
        );
        stargateStaking = IStargateStaking(
            constants.getAddress(
                string.concat(_strategyName, ".stargateStaking")
            )
        );
        stargateMultiRewarder = IMultiRewarder(
            constants.getAddress(
                string.concat(_strategyName, ".stargateMultiRewarder")
            )
        );

        wrappedNativeToken = constants.getAddress(
            string.concat(_strategyName, ".wrappedNativeToken")
        );

        vm.label(stargatePoolUSDC, "StargatePoolUSDC");
        vm.label(address(stargateStaking), "StargateStaking");
        vm.label(address(stargateMultiRewarder), "StargateMultiRewarder");
        vm.label(wrappedNativeToken, "WrappedNativeToken");
    }

    function setUp() public virtual override {
        fork(chainId, blockNumber);

        token = IERC20Metadata(address(USDC));

        super.setUp();

        IStrategy.StrategyParams memory strategyParams = IStrategy
            .StrategyParams(
                uint32(chainId),
                "Stargate",
                2,
                address(token),
                stargatePoolUSDC
            );

        strategy = _deploy_StargateV2Strategy(
            strategyParams,
            address(maatAddressProvider),
            address(stargateStaking),
            address(stargateMultiRewarder),
            feeTo,
            fee,
            address(wrappedNativeToken)
        );

        vm.label(address(strategy), "StargateV2Strategy");

        _afterSetUp();
    }

    function _afterSetUp() internal virtual {
        _prepareTokens();
    }
}
