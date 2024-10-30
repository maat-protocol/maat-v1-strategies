// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Strategy} from "../../Strategy.sol";
// import {IPool} from "@aave/core-v3/contracts/interfaces/IPool.sol";
import "@aave/core-v3/contracts/interfaces/IPool.sol";
import {IPoolAddressesProvider} from "@aave/core-v3/contracts/interfaces/IPoolAddressesProvider.sol";
import {IAToken} from "@aave/core-v3/contracts/interfaces/IAToken.sol";
import {IPoolDataProvider} from "@aave/core-v3/contracts/interfaces/IPoolDataProvider.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract AaveV3Strategy is Strategy {
    using SafeERC20 for ERC20;

    IPoolAddressesProvider public immutable PoolAddressesProvider;

    struct AaveData {
        uint reserveIsActive;
        uint reserveIsFrozen;
        uint assetIsPaused;
        uint supplyCap;
        uint assetDecimals;
        address aToken;
    }

    error NotEnoughAvailableLiquidity();

    constructor(
        StrategyParams memory _strategyParams,
        address _maatAddressProvider,
        address _poolAddressesProvider,
        address _feeTo,
        uint fee
    ) Strategy(_strategyParams, _maatAddressProvider, _feeTo, fee) {
        PoolAddressesProvider = IPoolAddressesProvider(_poolAddressesProvider);
    }

    function totalAssets()
        public
        view
        override
        returns (uint totalManagedAssets)
    {
        address aToken = _getAToken();
        totalManagedAssets = IAToken(aToken).balanceOf(address(this));
    }

    function maxDeposit(address) public view override returns (uint maxAssets) {
        // if (receiver != maatVault) return 0;

        maxAssets = _getAvailableToSupply();
    }

    function previewDeposit(
        uint assets
    ) public view override returns (uint256 shares) {
        if (assets == 0) revert ZeroAssets();

        uint availableToSupply = _getAvailableToSupply();

        if (assets > availableToSupply) revert DepositExceedsLimit();

        shares = convertToShares(assets);
    }

    function maxMint(address) public view override returns (uint256 maxShares) {
        // if (receiver != maatVault) return 0;

        uint availableToSupply = _getAvailableToSupply();

        maxShares = convertToShares(availableToSupply);
    }

    function previewMint(
        uint256 shares
    ) public view override returns (uint256 assets) {
        if (shares == 0) revert ZeroAssets();

        assets = convertToAssets(shares);

        if (assets == 0) revert ZeroAssets();

        uint availableToSupply = _getAvailableToSupply();

        if (assets > availableToSupply) revert DepositExceedsLimit();
    }

    function maxWithdraw(
        address owner
    ) public view override returns (uint256 maxAssets) {
        uint shares = balanceOf(owner);
        uint assets = convertToAssets(shares);

        uint globalMaxWithdraw = _getAvailableLiquidity();

        if (assets > globalMaxWithdraw) {
            return globalMaxWithdraw;
        }

        return convertToAssets(shares);
    }

    function previewWithdraw(
        uint256 assets
    ) public view override returns (uint256 shares) {
        uint globalMaxWithdraw = _getAvailableLiquidity();

        if (assets > globalMaxWithdraw) revert NotEnoughAvailableLiquidity();

        shares = convertToShares(assets);
    }

    function maxRedeem(
        address owner
    ) public view override returns (uint256 maxShares) {
        maxShares = balanceOf(owner);

        uint assets = convertToAssets(maxShares);

        uint globalMaxWithdraw = _getAvailableLiquidity();

        if (assets > globalMaxWithdraw) {
            return convertToShares(globalMaxWithdraw);
        }
    }

    function previewRedeem(
        uint256 shares
    ) public view override returns (uint256 assets) {
        assets = convertToAssets(shares);
        uint globalMaxWithdraw = _getAvailableLiquidity();

        if (assets > globalMaxWithdraw) revert NotEnoughAvailableLiquidity();
    }

    function _getAvailableToSupply()
        internal
        view
        returns (uint availableToSupply)
    {
        AaveData memory aaveData = _getAaveData();

        if (
            aaveData.reserveIsActive == 0 ||
            aaveData.reserveIsFrozen == 1 ||
            aaveData.assetIsPaused == 1
        ) {
            return 0;
        }

        uint aTokenTotalSupply = IAToken(aaveData.aToken).totalSupply();

        availableToSupply =
            (aaveData.supplyCap * 10 ** aaveData.assetDecimals) -
            aTokenTotalSupply;
    }

    function _getFromBits(
        uint input,
        uint start,
        uint end
    ) internal pure returns (uint) {
        uint afterLeftShift = input << (255 - end);

        uint afterRightShift = afterLeftShift >> (255 - (end - start));

        return afterRightShift;
    }

    function _afterBurn(
        address receiver,
        address,
        uint assets,
        uint
    ) internal override {
        address pool = _getPool();

        IPool(pool).withdraw(asset(), assets, receiver);
    }

    function _beforeMint(address, uint assets, uint) internal override {
        address pool = _getPool();

        token.approve(address(pool), assets);
        IPool(pool).supply(asset(), assets, address(this), 0);
    }

    function _getAvailableLiquidity()
        internal
        view
        returns (uint availableLiquidity)
    {
        AaveData memory aaveData = _getAaveData();

        if (aaveData.reserveIsActive == 0 || aaveData.assetIsPaused == 1) {
            return 0;
        }

        availableLiquidity = token.balanceOf(aaveData.aToken);
    }

    function _getAaveData() internal view returns (AaveData memory aaveData) {
        address pool = _getPool();

        DataTypes.ReserveData memory reserveData = IPool(pool).getReserveData(
            asset()
        );

        uint config = reserveData.configuration.data;

        uint reserveIsActive = _getFromBits(config, 56, 56);

        uint reserveIsFrozen = _getFromBits(config, 57, 57);

        uint assetIsPaused = _getFromBits(config, 60, 60);

        uint supplyCap = _getFromBits(config, 116, 151);

        uint assetDecimals = _getFromBits(config, 48, 55);

        aaveData = AaveData({
            reserveIsActive: reserveIsActive,
            reserveIsFrozen: reserveIsFrozen,
            assetIsPaused: assetIsPaused,
            supplyCap: supplyCap,
            assetDecimals: assetDecimals,
            aToken: reserveData.aTokenAddress
        });
    }

    function _getPool() internal view returns (address pool) {
        pool = PoolAddressesProvider.getPool();
    }

    function _getAToken() internal view returns (address aToken) {
        address aaveProtocolDataProvider = PoolAddressesProvider
            .getPoolDataProvider();
        (aToken, , ) = IPoolDataProvider(aaveProtocolDataProvider)
            .getReserveTokensAddresses(address(token));
    }
}
