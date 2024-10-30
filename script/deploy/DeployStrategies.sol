// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.22;

import {IStrategy} from "../../contracts/interfaces/IStrategy.sol";

import {YearnV3Strategy} from "../../contracts/strategies/Yearn/YearnV3Strategy.sol";
import {AaveV3Strategy} from "../../contracts/strategies/Aave/AaveV3Strategy.sol";
import {StargateV2Strategy} from "../../contracts/strategies/Stargate/StargateV2Strategy.sol";
import {HarvestV2Strategy} from "../../contracts/strategies/Harvest/HarvestV2Strategy.sol";
import {SuperformStrategy} from "../../contracts/strategies/Superform/SuperformStrategy.sol";

abstract contract DeployStrategies {
    function _deploy_AaveV3Strategy(
        IStrategy.StrategyParams memory _strategyParams,
        address _maatAddressProvider,
        address _poolAddressesProvider,
        address _feeTo,
        uint _fee
    ) internal returns (AaveV3Strategy strategy) {
        strategy = new AaveV3Strategy(
            _strategyParams,
            _maatAddressProvider,
            _poolAddressesProvider,
            _feeTo,
            _fee
        );
    }

    function _deploy_YearnV3Strategy(
        IStrategy.StrategyParams memory _strategyParams,
        address _maatAddressProvider,
        address _feeTo,
        uint _fee
    ) internal returns (YearnV3Strategy strategy) {
        strategy = new YearnV3Strategy(
            _strategyParams,
            _maatAddressProvider,
            _feeTo,
            _fee
        );
    }

    function _deploy_SuperformStrategy(
        IStrategy.StrategyParams memory _strategyParams,
        address _maatAddressProvider,
        address _router,
        uint256 _superformId,
        address _superPositions,
        address _feeTo,
        uint _fee
    ) internal returns (SuperformStrategy strategy) {
        strategy = new SuperformStrategy(
            _strategyParams,
            _maatAddressProvider,
            _router,
            _superformId,
            _superPositions,
            _feeTo,
            _fee
        );
    }

    function _deploy_StargateV2Strategy(
        IStrategy.StrategyParams memory _strategyParams,
        address _maatAddressProvider,
        address _stargateStaking,
        address _stargateMultiRewarder,
        address _feeTo,
        uint _fee,
        address _wrappedNativeToken
    ) internal returns (StargateV2Strategy strategy) {
        strategy = new StargateV2Strategy(
            _strategyParams,
            _maatAddressProvider,
            _stargateStaking,
            _stargateMultiRewarder,
            _feeTo,
            _fee,
            _wrappedNativeToken
        );
    }

    function _deploy_HarvestV2Strategy(
        IStrategy.StrategyParams memory _strategyParams,
        address _maatAddressProvider,
        address _harvestVault,
        address _harvestPotPool,
        address _feeTo,
        uint _fee
    ) internal returns (HarvestV2Strategy strategy) {
        strategy = new HarvestV2Strategy(
            _strategyParams,
            _maatAddressProvider,
            _harvestVault,
            _harvestPotPool,
            _feeTo,
            _fee
        );
    }
}
