// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.22;

import {BaseTest} from "../../utils.sol";

import {OpenOceanRouter} from "contracts/routers/OpenOcean/OpenOceanRouter.sol";
import {DeployIncentiveController} from "../../../script/deploy/DeployIncentiveController.sol";

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract OpenOceanRouterTestSetup is BaseTest, DeployIncentiveController {
    OpenOceanRouter public openOceanRouter;

    address openOceanExchange;

    constructor() {
        openOceanExchange = constants.getAddress("arbitrum.openOceanExchange");
    }

    function setUpOpenOceanRouter() internal {
        openOceanRouter = _deploy_OpenOceanRouter(
            0x9fBB3DF7C40Da2e5A0dE984fFE2CCB7C47cd0ABf,
            openOceanExchange,
            "OpenOceanRouter"
        );

        vm.label(address(openOceanRouter), "OpenOceanRouter");
    }

    function setUp() public virtual {
        fork(
            constants.defaultForkChainId(),
            constants.defaultForkBlockNumber()
        );

        setUpOpenOceanRouter();

        _afterSetUp();
    }

    function _afterSetUp() internal virtual {}
}
