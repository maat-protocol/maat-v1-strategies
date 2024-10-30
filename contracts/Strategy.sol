// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import {ERC165Checker} from "@openzeppelin/contracts/utils/introspection/ERC165Checker.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

import {FeeManager} from "./FeeManager.sol";

import {IStrategy, IERC4626} from "./interfaces/IStrategy.sol";
import {IMaatAddressProvider} from "./interfaces/IMaatAddressProvider.sol";

import {ERC165Registry} from "./lib/ERC165Registry.sol";
import {StrategyIdLib} from "./lib/StrategyIdLib.sol";

/// @title Strategy
/// @author MAAT Finance
/// @notice Base contract for all strategies
/// @dev This contract is intended to be inherited from, and not used directly
/* ======== Implementation Notes ======== */
/// @dev Implement _beforeMint() with deposit to underlying protocol
/// @dev Implement _afterBurn() with withdraw from underlying protocol
/// @dev Implement totalAssets() with getting all assets allocated to Strategy in Protocol Vault pool
/// @dev Implement maxDeposit()
abstract contract Strategy is
    IStrategy,
    ERC20,
    ERC165Registry,
    Ownable,
    FeeManager
{
    // Used for mulDiv with rounding operations to converts assets/shares
    using Math for uint;
    using SafeERC20 for ERC20;

    StrategyParams strategyParams;

    uint internal prevTotalAssets;

    ERC20 internal immutable token;

    IMaatAddressProvider public immutable MaatAddressProvider;

    bytes4 public constant StrategyInterfaceId =
        bytes4(keccak256("MAAT.V1.Strategy"));

    /* ============ ERRORS ============ */

    error ZeroAddress(string argument);
    error ZeroAssets();
    error ZeroShares();
    error CallerIsNotTokenVault();
    error DepositExceedsLimit();
    error InvalidAssetsInput();

    /* ============ CONSTRUCTOR ============ */

    constructor(
        StrategyParams memory _strategyParams,
        address _maatAddressProvider,
        address _feeTo,
        uint fee
    )
        Ownable(msg.sender)
        ERC20(
            getStrategyName(_strategyParams),
            getStrategySymbol(_strategyParams)
        )
        FeeManager(fee, _feeTo)
    {
        _validateFee(fee);

        strategyParams = _strategyParams;

        token = ERC20(_strategyParams.token);

        _registerInterface(StrategyInterfaceId);

        MaatAddressProvider = IMaatAddressProvider(_maatAddressProvider);
    }

    /* ============ ESSENTIAL VIEWS ============ */

    function asset() public view virtual returns (address assetTokenAddress) {
        return address(token);
    }

    // totalAssets assumes that ALL assets are ALWAYS deposited into the vault
    function totalAssets()
        public
        view
        virtual
        returns (uint256 totalManagedAssets)
    {
        // To be overridden by the Strategy implementation
    }

    function convertToShares(
        uint256 assets
    ) public view virtual returns (uint256 shares) {
        uint _totalAssets = totalAssets();

        if (_totalAssets == 0 && totalSupply() == 0) return assets;
        // Case where all funds are withdrawn, but shares still exist (then PPS = 0)
        if (_totalAssets == 0 && totalSupply() > 0) return 0;
        // Case where no shares exist, but assets still exist (then PPS = 1)
        // This case results in possibility of funds being stolen by another vault contract
        // Or it can results in arbitrary PPS changes after new deposit
        // due to PPS change immediately after deposit
        if (totalSupply() == 0 && _totalAssets > 0) return assets;

        return assets.mulDiv(totalSupply(), _totalAssets, Math.Rounding.Floor);
    }

    function convertToAssets(
        uint256 shares
    ) public view virtual returns (uint256 assets) {
        uint _totalSupply = totalSupply();

        if (totalSupply() == 0) return shares;

        return shares.mulDiv(totalAssets(), _totalSupply, Math.Rounding.Floor);
    }

    /* ============ DEPOSIT ============ */

    function maxDeposit(
        address receiver
    ) public view virtual returns (uint256 maxAssets) {
        // To be overridden by the Strategy implementation
    }

    function previewDeposit(
        uint256 assets
    ) public view virtual returns (uint256 shares) {
        shares = convertToShares(assets);
    }

    function deposit(
        uint256 assets,
        address receiver
    ) public virtual returns (uint256 shares) {
        if (assets == 0) revert ZeroAssets();
        if (receiver == address(0)) revert ZeroAddress("receiver");
        if (assets > maxDeposit(receiver)) revert DepositExceedsLimit();

        shares = convertToShares(assets);

        _deposit(receiver, assets, shares);
    }

    /* ============ MINT ============ */

    function maxMint(address) public view virtual returns (uint256 maxShares) {
        uint assets = maxDeposit(address(this));
        return convertToShares(assets);
    }

    function previewMint(
        uint256 shares
    ) public view virtual returns (uint256 assets) {
        assets = convertToAssets(shares);
    }

    function mint(
        uint256 shares,
        address receiver
    ) public virtual returns (uint256 assets) {
        assets = convertToAssets(shares);

        _deposit(receiver, assets, shares);
    }

    /* ============ WITHDRAW ============ */

    function maxWithdraw(
        address _owner
    ) public view virtual returns (uint256 maxAssets) {
        uint balance = balanceOf(_owner);
        return convertToAssets(balance);
    }

    function previewWithdraw(
        uint256 assets
    ) public view virtual returns (uint256 shares) {
        shares = convertToShares(assets);
    }

    function withdraw(
        uint256 assets,
        address receiver,
        address owner
    ) public virtual returns (uint256 shares) {
        shares = convertToShares(assets);

        _withdraw(receiver, owner, assets, shares);
    }

    /* ============ REDEEM ============ */

    function maxRedeem(
        address owner
    ) public view virtual returns (uint256 maxShares) {
        return balanceOf(owner);
    }

    function previewRedeem(
        uint256 shares
    ) public view virtual returns (uint256 assets) {
        assets = convertToAssets(shares);
    }

    function redeem(
        uint256 shares,
        address receiver,
        address owner
    ) public virtual returns (uint256 assets) {
        assets = convertToAssets(shares);

        _withdraw(receiver, owner, assets, shares);
    }

    /* ========== INTERNALS ========== */

    function _deposit(
        address receiver,
        uint assets,
        uint shares
    ) internal onlyTokenVault {
        if (receiver == address(0)) revert ZeroAddress("receiver");

        if (assets == 0) revert ZeroAssets();
        if (shares == 0) revert ZeroShares();

        // if (assets != convertToAssets(shares)) revert InvalidAssetsInput();
        if (assets > maxDeposit(receiver)) revert DepositExceedsLimit();

        uint yield = totalAssets() - prevTotalAssets;

        address sender = msg.sender;

        token.safeTransferFrom(sender, address(this), assets);

        _beforeMint(receiver, assets, shares);

        _mint(sender, shares);

        _afterMint(receiver, assets, shares);

        _mintFees(yield);
        _updatePrevTotalAssets();

        emit Deposit(sender, receiver, assets, shares);
    }

    /// @dev MUST deposit into Protocol before minting shares
    /// @dev MUST lock Protocol shares on Strategy implementation contract
    function _beforeMint(
        address receiver,
        uint assets,
        uint shares
    ) internal virtual {
        // To be overridden by the Strategy implementation
    }

    function _afterMint(
        address receiver,
        uint assets,
        uint shares
    ) internal virtual {
        // To be overridden by the Strategy implementation
    }

    /// @notice Withdraws funds from underlying protocol and burns shares
    /// @param receiver The address to receive the funds
    /// @param owner The address to burn the shares from
    /// @param assets The amount of assets to withdraw
    /// @param shares The amount of shares to burn
    /// @dev Shared implementation for withdraw and redeem
    /// @dev There is no onlyTokenVault() modifier for Fee Receiver to withdraw funds
    /// @dev Assets/shares amount must be precalculated with convertToAssets/convertToShares
    /// @dev before calling this function
    function _withdraw(
        address receiver,
        address owner,
        uint assets,
        uint shares
    ) internal {
        if (receiver == address(0)) revert ZeroAddress("receiver");
        if (owner == address(0)) revert ZeroAddress("owner");

        if (assets == 0) revert ZeroAssets();
        if (shares == 0) revert ZeroShares();

        uint yield = totalAssets() - prevTotalAssets;

        // if (assets != convertToAssets(shares)) revert InvalidAssetsInput();

        // TODO: should account for losses in the withdrawal process
        _beforeBurn(receiver, owner, assets, shares);

        shares = convertToShares(assets);

        _burn(msg.sender, shares);

        _afterBurn(receiver, owner, assets, shares);

        _mintFees(yield);
        _updatePrevTotalAssets();

        emit Withdraw(msg.sender, receiver, owner, assets, shares);
    }

    /// @dev MUST withdraw from Protocol using shares locked on Strategy implementation
    function _beforeBurn(
        address receiver,
        address owner,
        uint assets,
        uint shares
    ) internal virtual {
        // To be overridden by the Strategy implementation
    }

    function _afterBurn(
        address receiver,
        address owner,
        uint assets,
        uint shares
    ) internal virtual;

    function _mintFees(uint yield) internal {
        uint fee = _calculateFee(yield);
        uint sharesToMint = convertToShares(fee);
        _mint(feeTo, sharesToMint);
    }

    function _updatePrevTotalAssets() internal {
        prevTotalAssets = totalAssets();
    }

    /* ========== VIEW ========== */

    function getStrategyParams()
        public
        view
        override
        returns (StrategyParams memory)
    {
        return strategyParams;
    }

    function getStrategyName(
        StrategyParams memory _strategyParams
    ) public view virtual returns (string memory name) {
        // "MAAT PROTOCOL NAME V1 TOKEN"
        return
            string.concat(
                "MAAT ",
                _strategyParams.protocol,
                " V",
                Strings.toString(_strategyParams.protocolVersion),
                " ",
                ERC20(_strategyParams.token).symbol()
            );
    }

    function getStrategySymbol(
        StrategyParams memory _strategyParams
    ) public view virtual returns (string memory symbol) {
        return string.concat("mt", ERC20(_strategyParams.token).symbol()); // mtUSDC
    }

    function getStrategyId() public view returns (bytes32) {
        return StrategyIdLib.getStrategyId(strategyParams);
    }

    /* ========== MODIFIERS ========== */

    modifier onlyTokenVault() {
        if (!MaatAddressProvider.isVault(msg.sender))
            revert CallerIsNotTokenVault();
        _;
    }
}
