// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.22;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import {IncentiveController} from "../../contracts/IncentiveController.sol";
import {OpenOceanRouter} from "../../contracts/routers/OpenOcean/OpenOceanRouter.sol";
import {ISwapRouter} from "../../contracts/interfaces/ISwapRouter.sol";

import {OpenOceanRouterTestSetup} from "../routers/OpenOcean/_OpenOceanRouter.Setup.sol";
import {StargateV2StrategyTestSetup} from "../strategies/StargateStrategy/_StargateV2Strategy.Setup.sol";

contract IncentiveControllerTestSetup is
    OpenOceanRouterTestSetup,
    StargateV2StrategyTestSetup
{
    IncentiveController public incentiveController;

    address public compounder;
    address public incentiveControllerAdmin;

    constructor() {
        chainId = uint32(constants.defaultForkChainId());
        blockNumber = constants.defaultForkBlockNumber();
    }

    function setUp()
        public
        override(OpenOceanRouterTestSetup, StargateV2StrategyTestSetup)
    {
        super.setUp();

        setUpOpenOceanRouter();

        compounder = createUser(
            "compounder",
            address(uint160(uint256(keccak256(abi.encode("compounder")))))
        );

        incentiveControllerAdmin = createUser(
            "incentiveControllerAdmin",
            address(
                uint160(
                    uint256(keccak256(abi.encode("incentiveControllerAdmin")))
                )
            )
        );

        ISwapRouter[] memory swapRouters = new ISwapRouter[](1);
        swapRouters[0] = openOceanRouter;

        vm.startPrank(incentiveControllerAdmin);
        incentiveController = _deploy_IncentiveController(
            0x9fBB3DF7C40Da2e5A0dE984fFE2CCB7C47cd0ABf,
            incentiveControllerAdmin,
            compounder,
            swapRouters,
            "IncentiveController"
        );

        vm.stopPrank();

        vm.prank(admin);
        maatAddressProvider.changeIncentiveController(
            address(incentiveController)
        );

        vm.label(address(incentiveController), "IncentiveController");

        _prepareTokens();
    }

    function _afterSetUp()
        internal
        virtual
        override(OpenOceanRouterTestSetup, StargateV2StrategyTestSetup)
    {}
}
