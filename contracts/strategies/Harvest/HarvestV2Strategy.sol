// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.20;

import {Strategy} from "../../Strategy.sol";

import {IStrategyWithIncentives} from "../../interfaces/IStrategyWithIncentives.sol";

import {ERC165Registry, IERC165} from "../../lib/ERC165Registry.sol";

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC4626} from "@openzeppelin/contracts/interfaces/IERC4626.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import {IVault} from "./interfaces/IVault.sol";
import {IPotPool} from "./interfaces/IPotPool.sol";

contract HarvestV2Strategy is
    ERC165Registry,
    Strategy,
    IStrategyWithIncentives
{
    using SafeERC20 for IERC20;

    bytes4 public constant StrategyWithIncentivesInterfaceId =
        bytes4(keccak256("MAAT.V1.IStrategyWithIncentives"));

    IVault public immutable HarvestVault;
    IPotPool public immutable HarvestPotPool;

    uint256 public totalIncentives;

    constructor(
        StrategyParams memory _strategyParams,
        address _maatAddressProvider,
        address _harvestVault,
        address _potPool,
        address _feeTo,
        uint _fee
    ) Strategy(_strategyParams, _maatAddressProvider, _feeTo, _fee) {
        HarvestVault = IVault(_harvestVault);
        HarvestPotPool = IPotPool(_potPool);

        _registerInterface(type(IERC165).interfaceId);
        _registerInterface(StrategyWithIncentivesInterfaceId);
    }

    function totalAssets() public view override returns (uint256) {
        uint256 stakedShares = HarvestPotPool.stakedBalanceOf(address(this));

        return HarvestVault.previewRedeem(stakedShares);
    }

    function maxDeposit(address) public view override returns (uint256) {
        return HarvestVault.maxDeposit(address(this));
    }

    function _beforeMint(address, uint assets, uint) internal override {
        token.approve(address(HarvestVault), assets);
        uint256 shares = HarvestVault.deposit(assets, address(this));

        HarvestVault.approve(address(HarvestPotPool), shares);
        HarvestPotPool.stake(shares);
    }

    function _afterBurn(
        address receiver,
        address,
        uint assets,
        uint
    ) internal override {
        uint256 shares = HarvestVault.previewWithdraw(assets);

        HarvestPotPool.withdraw(shares);

        HarvestVault.redeem(shares, receiver, address(this));
    }

    function previewHarvest()
        public
        view
        returns (address[] memory rewardTokens, uint256[] memory rewards)
    {
        (
            address[] memory _rewardTokens,
            uint256[] memory _rewards
        ) = pendingRewards(true);

        (rewardTokens, rewards) = _filterZeroRewards(_rewardTokens, _rewards);
    }

    function harvest()
        external
        onlyIncentivesController
        returns (address[] memory rewardTokens, uint256[] memory rewards)
    {
        address incentivesControllerAddress = MaatAddressProvider
            .incentiveController();

        (rewardTokens, ) = previewHarvest();

        rewards = new uint256[](rewardTokens.length);

        for (uint i = 0; i < rewardTokens.length; i++) {
            IERC20 rewardToken = IERC20(rewardTokens[i]);

            HarvestPotPool.getReward(address(rewardToken));

            uint256 balance = rewardToken.balanceOf(address(this));

            rewards[i] = balance;
            rewardToken.safeTransfer(incentivesControllerAddress, balance);
        }
    }

    function compound(uint256 amount) external onlyIncentivesController {
        _beforeMint(address(0), amount, 0);

        totalIncentives += amount;
    }

    function getRewardTokens()
        public
        view
        returns (address[] memory rewardTokens)
    {
        uint256 len = HarvestPotPool.rewardTokensLength();

        rewardTokens = new address[](len);

        for (uint i = 0; i < len; i++)
            rewardTokens[i] = HarvestPotPool.rewardTokens(i);
    }

    function pendingRewards(
        bool addBalanceOf
    )
        public
        view
        returns (address[] memory rewardTokens, uint256[] memory rewards)
    {
        rewardTokens = getRewardTokens();

        uint256 len = rewardTokens.length;

        rewards = new uint256[](len);

        for (uint i = 0; i < len; i++) {
            address rewardToken = rewardTokens[i];

            rewards[i] = HarvestPotPool.earned(rewardToken, address(this));

            if (addBalanceOf)
                rewards[i] += IERC20(rewardToken).balanceOf(address(this));
        }
    }

    function _filterZeroRewards(
        address[] memory rewardTokens,
        uint256[] memory rewards
    )
        internal
        pure
        returns (address[] memory _rewardTokens, uint256[] memory _rewards)
    {
        uint256 nonZeroRewardsCounter;

        uint256 len = rewards.length;

        for (uint i = 0; i < len; i++)
            if (rewards[i] > 0) nonZeroRewardsCounter++;

        _rewardTokens = new address[](nonZeroRewardsCounter);
        _rewards = new uint256[](nonZeroRewardsCounter);

        nonZeroRewardsCounter = 0;

        for (uint i = 0; i < len; i++)
            if (rewards[i] > 0) {
                _rewardTokens[nonZeroRewardsCounter] = rewardTokens[i];
                _rewards[nonZeroRewardsCounter] = rewards[i];
                nonZeroRewardsCounter++;
            }
    }

    error OnlyIncentivesController();

    modifier onlyIncentivesController() {
        if (msg.sender != MaatAddressProvider.incentiveController())
            revert OnlyIncentivesController();
        _;
    }
}
