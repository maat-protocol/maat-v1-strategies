// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.22;

import {Strategy, IStrategy} from "../../contracts/Strategy.sol";
import {YearnV3Strategy} from "../../contracts/strategies/Yearn/YearnV3Strategy.sol";

import {StrategyTestSetup} from "./_Strategy.Setup.sol";

import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {IERC4626} from "@openzeppelin/contracts/interfaces/IERC4626.sol";

contract StrategyMockImplSetup is StrategyTestSetup {
    uint32 chainId;
    uint256 blockNumber;

    address feeTo = address(0xbeefbeffbeefbeefbeffbeefbefefbeffbeef);
    uint fee = 10 ** 7;

    IERC4626 yearnVault;

    constructor() {
        chainId = 137;
        blockNumber = 58068067;

        token = IERC20Metadata(address(constants.getAddress("polygon.usdc")));
        USDC = token;

        yearnVault = IERC4626(constants.getAddress("polygon.yearnUSDCVault"));
    }

    function setUp() public virtual override {
        fork(chainId, blockNumber);
        token = IERC20Metadata(address(USDC));

        super.setUp();

        strategyParams = IStrategy.StrategyParams(
            chainId,
            "Yearn",
            3,
            address(USDC),
            address(yearnVault)
        );

        strategy = _deploy_YearnV3Strategy(
            strategyParams,
            address(maatAddressProvider),
            feeTo,
            fee
        );

        vm.prank(admin);
        maatAddressProvider.addStrategy(address(strategy));

        vm.label(address(strategy), "Strategy");

        _prepareTokens();
    }
}

contract StrategyMockImpl is Strategy {
    constructor(
        StrategyParams memory _strategyParams,
        address maatAddressProvider,
        address _feeTo,
        uint fee
    ) Strategy(_strategyParams, maatAddressProvider, _feeTo, fee) {}

    function totalAssets()
        public
        view
        override
        returns (uint256 totalManagedAssets)
    {}

    function maxDeposit(
        address
    ) public view override returns (uint256 maxAssets) {}

    function _beforeMint(
        address receiver,
        uint assets,
        uint shares
    ) internal override {}

    function _afterBurn(
        address receiver,
        address owner,
        uint assets,
        uint shares
    ) internal virtual override {}
}
