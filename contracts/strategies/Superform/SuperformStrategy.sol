// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Strategy} from "../../Strategy.sol";
import {IBaseForm} from "./vendor/IBaseForm.sol";
import {IBaseRouterImplementation} from "./vendor/IBaseRouterImplementation.sol";
import {SingleDirectSingleVaultStateReq, SingleVaultSFData, LiqRequest} from "./vendor/DataTypes.sol";
import {IERC4626} from "@openzeppelin/contracts/interfaces/IERC4626.sol";
import {IERC1155Receiver} from "@openzeppelin/contracts/interfaces/IERC1155Receiver.sol";
import {IERC1155A} from "./vendor/IERC1155A.sol";

/// @dev Assumes that underlying protocol value is ERC4626 compliant
/// @dev otherwise, the strategy will not work as expected
contract SuperformStrategy is Strategy {
    IBaseForm public immutable superform;
    IBaseRouterImplementation public immutable router;
    uint256 public immutable superformId;
    IERC1155A public immutable superPositions;

    constructor(
        StrategyParams memory _strategyParams,
        address _maatAddressProvider,
        address _router,
        uint256 _superformId,
        address _superPositions,
        address _feeTo,
        uint fee
    ) Strategy(_strategyParams, _maatAddressProvider, _feeTo, fee) {
        router = IBaseRouterImplementation(_router);
        superformId = _superformId;
        superform = IBaseForm(_strategyParams.protocolVault);
        superPositions = IERC1155A(_superPositions);

        _registerInterface(type(IERC1155Receiver).interfaceId);
    }

    function totalAssets()
        public
        view
        override
        returns (uint256 totalManagedAssets)
    {
        uint shares = superPositions.balanceOf(address(this), superformId);
        return superform.previewRedeemFrom(shares);
    }

    function maxDeposit(
        address
    ) public view override returns (uint256 maxAssets) {
        return IERC4626(superform.getVaultAddress()).maxDeposit(address(this));
    }

    function _beforeMint(address, uint assets, uint) internal override {
        token.approve(address(router), assets);
        // Stores yTokens on Strategy
        // Sends mtTokens to maatVault

        uint shares = superform.previewDepositTo(assets);

        LiqRequest memory liqRequest = LiqRequest(
            /// @dev generated data
            bytes(""), // txData
            /// @dev input token for deposits, desired output token on target liqDstChainId for withdraws. Must be set for
            /// txData to be updated on destination for withdraws
            asset(),
            /// @dev intermediary token on destination. Relevant for xChain deposits where a destination swap is needed for
            /// validation purposes
            address(0),
            /// @dev what bridge to use to move tokens
            uint8(0),
            /// @dev dstChainId = liqDstchainId for deposits. For withdraws it is the target chain id for where the underlying
            /// is to be delivered
            uint64(strategyParams.chainId),
            /// @dev currently this amount is used as msg.value in the txData call.
            uint256(0)
        );

        SingleVaultSFData memory singleVaultData = SingleVaultSFData(
            superformId,
            assets,
            shares, // on deposits, amount of shares to receive, on withdrawals, amount of assets to receive
            0,
            liqRequest, // if length = 1; amount = sum(amounts)| else  amounts must match the amounts being sent
            bytes(""), // Permit2
            false, // hasDstSwap
            false, // if true, we don't mint SuperPositions, and send the 4626 back to the user instead
            address(this), // receiver
            /// this address must always be an EOA otherwise funds may be lost
            address(this),
            /// this address can be a EOA or a contract that implements onERC1155Receiver. must always be set for deposits
            bytes("") // extraFormData
        );

        SingleDirectSingleVaultStateReq
            memory req = SingleDirectSingleVaultStateReq(singleVaultData);

        router.singleDirectSingleVaultDeposit(req);
    }

    function _afterBurn(address, address, uint assets, uint) internal override {
        superPositions.setApprovalForOne(
            address(router),
            superformId,
            type(uint).max
        );

        LiqRequest memory liqRequest = LiqRequest(
            /// @dev generated data
            bytes(""), // txData
            /// @dev input token for deposits, desired output token on target liqDstChainId for withdraws. Must be set for
            /// txData to be updated on destination for withdraws
            asset(),
            /// @dev intermediary token on destination. Relevant for xChain deposits where a destination swap is needed for
            /// validation purposes
            address(0),
            /// @dev what bridge to use to move tokens
            uint8(0),
            /// @dev dstChainId = liqDstchainId for deposits. For withdraws it is the target chain id for where the underlying
            /// is to be delivered
            uint64(strategyParams.chainId),
            /// @dev currently this amount is used as msg.value in the txData call.
            uint256(0)
        );

        uint shares = superform.previewWithdrawFrom(assets);

        SingleVaultSFData memory singleVaultData = SingleVaultSFData(
            superformId,
            shares, // amount
            assets, // outputAmount on deposits, amount of shares to receive, on withdrawals, amount of assets to receive
            0,
            liqRequest, // if length = 1; amount = sum(amounts)| else  amounts must match the amounts being sent
            bytes(""), // Permit2
            false, // hasDstSwap
            false, // if true, we don't mint SuperPositions, and send the 4626 back to the user instead
            msg.sender, // receiver
            /// this address must always be an EOA otherwise funds may be lost
            address(this),
            /// this address can be a EOA or a contract that implements onERC1155Receiver. must always be set for deposits
            bytes("") // extraFormData
        );

        SingleDirectSingleVaultStateReq
            memory req = SingleDirectSingleVaultStateReq(singleVaultData);

        router.singleDirectSingleVaultWithdraw(req);
    }

    /* ======== ERC1155 Receiver ======== */

    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes memory
    ) public pure returns (bytes4) {
        return this.onERC1155Received.selector;
    }
}
