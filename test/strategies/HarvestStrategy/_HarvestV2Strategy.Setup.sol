// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.22;

import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {IStrategy} from "../../../contracts/interfaces/IStrategy.sol";

import {StrategyTestSetup} from "../../Strategy/_Strategy.Setup.sol";

contract HarvestV2StrategyTestSetup is StrategyTestSetup {
    address harvestVault;
    address harvestPotPool;

    address feeTo = address(0xbeefbeffbeefbeefbeffbeefbefefbeffbeef);
    uint fee = 10 ** 7;

    uint32 chainId;
    uint256 blockNumber;

    address governance = address(0xF066789028fE31D4f53B69B81b328B8218Cc0641);
    address controller = address(0x68B2FC1566f411C1Af8fF5bFDA3dD4F3F3e59D03);

    constructor() {
        chainId = uint32(constants.defaultForkChainId());
        blockNumber = 251367280; //constants.defaultForkBlockNumber();

        harvestVault = constants.getAddress("arbitrum.harvestVault");
        harvestPotPool = constants.getAddress("arbitrum.harvestPotPool");

        vm.label(harvestVault, "HarvestVault");
        vm.label(harvestPotPool, "HarvestPotPool");
    }

    function setUp() public virtual override {
        fork(chainId, blockNumber);

        token = IERC20Metadata(address(USDC));

        super.setUp();

        IStrategy.StrategyParams memory strategyParams = IStrategy
            .StrategyParams(
                uint32(chainId),
                "Harvest:Loadstar",
                2,
                address(token),
                harvestVault
            );

        strategy = _deploy_HarvestV2Strategy(
            strategyParams,
            address(maatAddressProvider),
            harvestVault,
            harvestPotPool,
            feeTo,
            fee
        );

        vm.prank(governance);
        (bool success, ) = address(controller).call(
            abi.encodeWithSignature(
                "addToWhitelist(address)",
                address(strategy)
            )
        );

        require(success, "Failed to add to whitelist");

        vm.label(address(strategy), "HarvestV2Strategy");

        _afterSetUp();
    }

    function _afterSetUp() internal virtual {
        _prepareTokens();
    }

    function doHardWork() internal {
        vm.prank(governance);
        (bool success, ) = controller.call(
            abi.encodeWithSignature("addHardWorker(address)", alice)
        );
        assertTrue(success);

        vm.prank(alice);
        (success, ) = controller.call(
            abi.encodeWithSignature(
                "doHardWork(address)",
                address(harvestVault)
            )
        );
        assertTrue(success);
    }
}
