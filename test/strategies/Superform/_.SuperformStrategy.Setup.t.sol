// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {SuperformStrategy} from "../../../contracts/strategies/Superform/SuperformStrategy.sol";
import {IStrategy} from "../../../contracts/interfaces/IStrategy.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {IBaseForm} from "../../../contracts/strategies/Superform/vendor/IBaseForm.sol";
import {IERC1155A} from "../../../contracts/strategies/Superform/vendor/IERC1155A.sol";
import {IBaseRouterImplementation} from "../../../contracts/strategies/Superform/vendor/IBaseRouterImplementation.sol";

import {StrategyTestSetup, IERC20Metadata} from "../../Strategy/_Strategy.Setup.sol";

contract SuperformStrategyTestSetup is StrategyTestSetup {
    uint immutable timeWarp = 200 weeks;

    address feeTo = address(0xbeefbeffbeefbeefbeffbeefbefefbeffbeef);

    SuperformStrategy superformStrategy;

    address addressesProvider = 0xa97684ead0e402dC232d5A977953DF7ECBaB3CDb;

    /* ======== SUPERFORM VALUES ======== */

    uint256 superformId;
    IBaseRouterImplementation superformRouter;
    address superRegistry;
    IERC1155A superPositions;
    address fluidLiquidityProxy;
    address erc4226Form;

    uint amount = 1e8;

    uint32 chainId;
    uint256 forkBlockNumber;

    IBaseForm protocolVault;

    constructor() {
        chainId = uint32(constants.defaultForkChainId());
        forkBlockNumber = 263378290;

        superformId = 264648886265639367981557968147687766195622338050783517213617753;
        superformRouter = IBaseRouterImplementation(
            0xa195608C2306A26f727d5199D5A382a4508308DA
        );
        superRegistry = 0x17A332dC7B40aE701485023b219E9D6f493a2514;
        superPositions = IERC1155A(0x01dF6fb6a28a89d6bFa53b2b3F20644AbF417678);
        fluidLiquidityProxy = 0x58F8Cef0D825B1a609FaD0576d5F2b7399ab1335;
        erc4226Form = 0x58F8Cef0D825B1a609FaD0576d5F2b7399ab1335;
        protocolVault = IBaseForm(0x0a4c7F243153de871D6029f8b69125eC7Dbe6e59); // Fluid Superform

        token = ERC20(0xaf88d065e77c8cC2239327C5EDb3A432268e5831);
    }

    function setUp() public override {
        fork(chainId, forkBlockNumber);

        _beforeSetup();

        super.setUp();

        /* ======== STRATEGY DEPLOYMENT ======== */

        strategyParams = IStrategy.StrategyParams(
            42161,
            "Superform",
            2,
            asset(),
            address(protocolVault)
        );

        superformStrategy = new SuperformStrategy(
            strategyParams,
            address(maatAddressProvider),
            address(superformRouter),
            superformId,
            address(superPositions),
            feeTo,
            10 ** 7
        );

        strategy = superformStrategy;

        /* ======== PREPARE TOKENS ======== */

        _prepareTokens();

        /* ======== LABELS ======== */

        vm.label(address(this), "Test MAAT Vault");
        vm.label(address(superformStrategy), "superformStrategy");
        vm.label(address(superformRouter), "Superform Router");
        vm.label(address(protocolVault), "Fluid Superform");
        vm.label(erc4226Form, "ERC4626 Form");
        vm.label(fluidLiquidityProxy, "FluidLiquidityProxy");
        vm.label(address(superPositions), "SuperPosition (ERC1155)");
        vm.label(superRegistry, "SuperRegistry");
        vm.label(
            0x1A996cb54bb95462040408C06122D45D6Cdb6096,
            "fToken (Vault Implementation)"
        );

        _afterSetUp();
    }

    function _deposit(uint _dealAmount, uint _amount) internal {
        deal(asset(), maatVault, _dealAmount);

        token.approve(address(superformStrategy), _dealAmount);

        superformStrategy.deposit(_amount, maatVault);
    }

    function _mint(uint _dealAmount, uint _amount) internal {
        vm.startPrank(maatVault);

        deal(asset(), maatVault, _dealAmount);

        token.approve(address(superformStrategy), _dealAmount);

        superformStrategy.mint(_amount, maatVault);
    }

    function _afterSetUp() internal virtual {}

    function _beforeSetup() internal virtual {}
}
