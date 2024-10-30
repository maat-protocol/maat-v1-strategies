// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.22;

import {IncentiveController} from "../../contracts/IncentiveController.sol";

import {CREATE3Factory} from "@layerzerolabs/create3-factory/contracts/CREATE3Factory.sol";

import {OpenOceanRouter} from "../../contracts/routers/OpenOcean/OpenOceanRouter.sol";
import {ISwapRouter} from "../../contracts/interfaces/ISwapRouter.sol";

abstract contract DeployIncentiveController {
    function _deploy_IncentiveController(
        address _create3Factory,
        address _admin,
        address _compounder,
        ISwapRouter[] memory _swapRouters,
        string memory _forSalt
    ) internal returns (IncentiveController incentiveController) {
        CREATE3Factory factory = CREATE3Factory(_create3Factory);

        bytes32 salt = keccak256(abi.encodePacked(_forSalt));
        bytes memory _deployedCode = type(IncentiveController).creationCode;
        bytes memory params = abi.encode(_admin, _compounder);
        bytes memory creationCode = abi.encodePacked(_deployedCode, params);

        incentiveController = IncentiveController(
            factory.deploy(salt, creationCode)
        );

        for (uint256 i = 0; i < _swapRouters.length; i++) {
            incentiveController.addSwapRouter(address(_swapRouters[i]));
        }
    }

    function _deploy_OpenOceanRouter(
        address _create3Factory,
        address _openOceanExchange,
        string memory _forSalt
    ) internal returns (OpenOceanRouter openOceanRouter) {
        CREATE3Factory factory = CREATE3Factory(_create3Factory);

        bytes32 salt = keccak256(abi.encodePacked(_forSalt));
        bytes memory _deployedCode = type(OpenOceanRouter).creationCode;
        bytes memory params = abi.encode(_openOceanExchange);
        bytes memory creationCode = abi.encodePacked(_deployedCode, params);

        openOceanRouter = OpenOceanRouter(factory.deploy(salt, creationCode));
    }
}
