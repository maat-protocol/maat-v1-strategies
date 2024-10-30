// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.20;

import {Strategy} from "../../Strategy.sol";

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import {IWETH9} from "../../interfaces/IWETH9.sol";

import {IStargateStaking} from "@stargatefinance/stg-evm-v2/src/peripheral/rewarder/interfaces/IStargateStaking.sol";
import {IMultiRewarder} from "@stargatefinance/stg-evm-v2/src/peripheral/rewarder/interfaces/IMultiRewarder.sol";
import {IStargatePool} from "@stargatefinance/stg-evm-v2/src/interfaces/IStargatePool.sol";

import {IStrategyWithIncentives} from "../../interfaces/IStrategyWithIncentives.sol";

import {ERC165Registry, IERC165} from "../../lib/ERC165Registry.sol";

contract StargateV2Strategy is
    ERC165Registry,
    Strategy,
    IStrategyWithIncentives
{
    using SafeERC20 for IERC20;
    error OnlyIncentivesController();

    IStargatePool public StargatePool;
    IStargateStaking public StargateStaking;
    IMultiRewarder public MultiRewarder;

    uint256 public totalIncentives;

    IERC20 public immutable StargateLpToken;

    bytes4 public constant StrategyWithIncentivesInterfaceId =
        bytes4(keccak256("MAAT.V1.IStrategyWithIncentives"));

    IWETH9 public immutable WrappedNativeToken;

    mapping(address => bool) public isNativeToken;

    constructor(
        StrategyParams memory _strategyParams,
        address _maatAddressProvider,
        address _stargateStaking,
        address _multiRewarder,
        address _feeTo,
        uint256 _fee,
        address _wrappedNativeToken
    ) Strategy(_strategyParams, _maatAddressProvider, _feeTo, _fee) {
        StargatePool = IStargatePool(_strategyParams.protocolVault);
        StargateStaking = IStargateStaking(_stargateStaking);
        MultiRewarder = IMultiRewarder(_multiRewarder);

        WrappedNativeToken = IWETH9(_wrappedNativeToken);

        StargateLpToken = IERC20(
            IStargatePool(_strategyParams.protocolVault).lpToken()
        );

        _registerInterface(type(IERC165).interfaceId);
        _registerInterface(StrategyWithIncentivesInterfaceId);

        isNativeToken[0x0000000000000000000000000000000000000000] = true;
        isNativeToken[0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE] = true;
        isNativeToken[0x0000000000000000000000000000000000001010] = true;
    }

    function _afterBurn(
        address receiver,
        address,
        uint assets,
        uint
    ) internal override {
        StargateStaking.withdraw(StargateLpToken, assets);

        StargatePool.redeem(assets, receiver);
    }

    function _beforeMint(address, uint assets, uint) internal override {
        token.approve(address(StargatePool), assets);
        uint256 amount = StargatePool.deposit(address(this), assets);

        StargateLpToken.approve(address(StargateStaking), amount);
        StargateStaking.deposit(StargateLpToken, amount);
    }

    function totalAssets()
        public
        view
        override
        returns (uint totalManagedAssets)
    {
        totalManagedAssets = StargateStaking.balanceOf(
            StargateLpToken,
            address(this)
        );
    }

    function maxDeposit(address) public pure override returns (uint maxAssets) {
        // if (receiver != maatVault) return 0;

        return type(uint).max;
    }

    function previewDeposit(
        uint assets
    ) public view override returns (uint256 shares) {
        // if (assets == 0) revert ZeroAssets();
        // uint availableToSupply = _getAvailableToSupply();
        // if (assets > availableToSupply) revert DepositExceedsLimit();
        shares = convertToShares(assets);
    }

    function maxMint(address) public view override returns (uint256 maxShares) {
        // if (receiver != maatVault) return 0;
        // uint availableToSupply = _getAvailableToSupply();
        maxShares = convertToShares(type(uint).max);
    }

    function previewMint(
        uint256 shares
    ) public view override returns (uint256 assets) {
        // if (shares == 0) revert ZeroAssets();
        assets = convertToAssets(shares);
        // if (assets == 0) revert ZeroAssets();
        // uint availableToSupply = _getAvailableToSupply();
        // if (assets > availableToSupply) revert DepositExceedsLimit();
    }

    function maxWithdraw(
        address owner
    ) public view override returns (uint256 maxAssets) {
        uint256 cap = StargatePool.redeemable(address(0));

        uint256 stargatePoolLpBalance = StargateStaking.balanceOf(
            StargateLpToken,
            address(this)
        );

        uint256 available = stargatePoolLpBalance > cap
            ? cap
            : stargatePoolLpBalance;

        uint256 assets = convertToAssets(balanceOf(owner));

        maxAssets = assets > available ? available : assets;
    }

    function previewWithdraw(
        uint256 assets
    ) public view override returns (uint256 shares) {
        require(
            maxWithdraw(msg.sender) >= assets,
            "[StargateV2Strategy]: Not enough assets to withdraw"
        );
        shares = convertToShares(assets);
    }

    function maxRedeem(
        address owner
    ) public view override returns (uint256 maxShares) {
        uint256 maxAssets = maxWithdraw(owner);

        maxShares = convertToShares(maxAssets);
    }

    function previewRedeem(
        uint256 shares
    ) public view override returns (uint256 assets) {
        require(
            maxWithdraw(msg.sender) >= convertToAssets(shares),
            "[StargateV2Strategy]: Not enough assets to redeem"
        );

        assets = convertToAssets(shares);
    }

    // ====================
    //      Incentives
    // ====================

    function pendingRewards()
        external
        view
        returns (address[] memory rewardTokens, uint256[] memory rewards)
    {
        (rewardTokens, rewards) = MultiRewarder.getRewards(
            StargateLpToken,
            address(this)
        );

        for (uint i = 0; i < rewardTokens.length; i++) {
            if (!isNativeToken[rewardTokens[i]]) continue;

            rewardTokens[i] = address(WrappedNativeToken);
        }
    }

    function previewHarvest()
        external
        view
        returns (address[] memory rewardTokens, uint256[] memory rewards)
    {
        (rewardTokens, rewards) = MultiRewarder.getRewards(
            StargateLpToken,
            address(this)
        );

        uint256 nonZeroRewardsCounter;

        for (uint i = 0; i < rewardTokens.length; i++) {
            if (isNativeToken[rewardTokens[i]]) {
                rewards[i] += address(this).balance;
                rewardTokens[i] = address(WrappedNativeToken);
            } else
                rewards[i] += IERC20(rewardTokens[i]).balanceOf(address(this));

            if (rewards[i] > 0) nonZeroRewardsCounter++;
        }

        (rewardTokens, rewards) = _filterZeroRewards(
            rewardTokens,
            rewards,
            nonZeroRewardsCounter
        );
    }

    function harvest()
        external
        onlyIncentivesController
        returns (address[] memory rewardTokens, uint256[] memory rewards)
    {
        address incentivesControllerAddress = MaatAddressProvider
            .incentiveController();

        IERC20[] memory lpTokens = new IERC20[](1);
        lpTokens[0] = StargateLpToken;
        StargateStaking.claim(lpTokens);

        rewardTokens = MultiRewarder.rewardTokens();
        rewards = new uint256[](rewardTokens.length);

        uint256 len = rewardTokens.length;
        uint256 nonZeroRewardsCounter;

        for (uint i = 0; i < len; i++) {
            // Converts rewards in Native to Wrapped Native
            if (isNativeToken[rewardTokens[i]]) {
                uint256 rewardsInNative = address(this).balance;
                WrappedNativeToken.deposit{value: rewardsInNative}();

                rewardTokens[i] = address(WrappedNativeToken);
            }

            uint balance = IERC20(rewardTokens[i]).balanceOf(address(this));

            rewards[i] = balance;

            if (balance == 0) continue;

            nonZeroRewardsCounter++;
            IERC20(rewardTokens[i]).safeTransfer(
                incentivesControllerAddress,
                balance
            );
        }

        (rewardTokens, rewards) = _filterZeroRewards(
            rewardTokens,
            rewards,
            nonZeroRewardsCounter
        );
    }

    function compound(uint256 amount) external onlyIncentivesController {
        _beforeMint(address(0), amount, 0);

        totalIncentives += amount;
    }

    function _filterZeroRewards(
        address[] memory rewardTokens,
        uint256[] memory rewards,
        uint256 nonZeroRewardsCounter
    )
        private
        pure
        returns (address[] memory _rewardTokens, uint256[] memory _rewards)
    {
        _rewardTokens = new address[](nonZeroRewardsCounter);
        _rewards = new uint256[](nonZeroRewardsCounter);

        nonZeroRewardsCounter = 0;

        uint256 len = rewardTokens.length;
        for (uint i = 0; i < len; i++) {
            if (rewards[i] > 0) {
                _rewardTokens[nonZeroRewardsCounter] = rewardTokens[i];
                _rewards[nonZeroRewardsCounter] = rewards[i];
                nonZeroRewardsCounter++;
            }
        }
    }

    modifier onlyIncentivesController() {
        if (msg.sender != MaatAddressProvider.incentiveController())
            revert OnlyIncentivesController();
        _;
    }

    receive() external payable {}
}
