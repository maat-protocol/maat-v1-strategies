// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {AaveV3Strategy} from "../../../contracts/strategies/Aave/AaveV3Strategy.sol";
import {IStrategy} from "../../../contracts/interfaces/IStrategy.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {IPoolConfigurator} from "@aave/core-v3/contracts/interfaces/IPoolConfigurator.sol";
import {IACLManager} from "@aave/core-v3/contracts/interfaces/IACLManager.sol";

// import "../../../contracts/core/Gateway.sol";
// import "../../../src/periphery/OraclePPS.sol";
// import "../../CrossChainVault/_.LayerZeroEndpoint.Setup.sol";

import {StrategyTestSetup, IERC20Metadata} from "../../Strategy/_Strategy.Setup.sol";

contract AaveStrategyHarness is AaveV3Strategy {
    constructor(
        StrategyParams memory _strategyParams,
        address _maatAddressProvider,
        address _poolAddressesProvider,
        address _feeTo,
        uint fee
    )
        AaveV3Strategy(
            _strategyParams,
            _maatAddressProvider,
            _poolAddressesProvider,
            _feeTo,
            fee
        )
    {}

    function exposed__getFromBits(
        uint256 input,
        uint256 start,
        uint256 end
    ) external pure returns (uint256) {
        return _getFromBits(input, start, end);
    }

    function exposed_getAvailableToSupply() external view returns (uint256) {
        return _getAvailableToSupply();
    }

    function exposed_getAvailableLiquidity() external view returns (uint256) {
        return _getAvailableLiquidity();
    }

    function exposed_getAToken() external view returns (address) {
        return _getAToken();
    }
}

contract AaveStrategyTestSetup is StrategyTestSetup {
    uint immutable timeWarp = 200 weeks;

    address feeTo = address(0xbeefbeffbeefbeefbeffbeefbefefbeffbeef);

    AaveStrategyHarness AaveStrategyContract;

    ERC20 DAI = ERC20(0xDA10009cBd5D07dd0CeCc66161FC93D7c9000da1);
    address addressesProvider = 0xa97684ead0e402dC232d5A977953DF7ECBaB3CDb;

    uint availableToSupply = 59220283814628;
    uint amount = 1e8;

    uint32 chainId;
    uint256 forkBlockNumber;

    constructor() {
        chainId = uint32(constants.defaultForkChainId());
        forkBlockNumber = 221121596;
    }

    // OracleGlobalPPS oracle;
    // Gateway gateway;

    function setUp() public override {
        fork(chainId, forkBlockNumber);
        token = IERC20Metadata(address(USDT));

        super.setUp();

        IStrategy.StrategyParams memory strategyParams = IStrategy
            .StrategyParams(42161, "Aave", 3, address(token), address(0));

        AaveStrategyContract = new AaveStrategyHarness(
            strategyParams,
            address(maatAddressProvider),
            addressesProvider,
            feeTo,
            10 ** 7
        );

        vm.label(address(AaveStrategyContract), "AaveStrategy");

        _afterSetup();
    }

    function _deposit(uint _dealAmount, uint _amount) internal {
        deal(address(token), maatVault, _dealAmount);

        token.approve(address(AaveStrategyContract), _dealAmount);

        AaveStrategyContract.deposit(_amount, maatVault);
    }

    function _mint(uint _dealAmount, uint _amount) internal {
        vm.startPrank(maatVault);

        deal(address(token), maatVault, _dealAmount);

        token.approve(address(AaveStrategyContract), _dealAmount);

        AaveStrategyContract.mint(_amount, maatVault);
    }

    function _setPoolPause() internal {
        address aclManager = AaveStrategyContract
            .PoolAddressesProvider()
            .getACLManager();

        address roleAdmin = AaveStrategyContract
            .PoolAddressesProvider()
            .getACLAdmin();

        vm.startPrank(roleAdmin);

        IACLManager(aclManager).addEmergencyAdmin(maatVault);

        vm.startPrank(maatVault);

        address poolConfigurator = AaveStrategyContract
            .PoolAddressesProvider()
            .getPoolConfigurator();

        IPoolConfigurator(poolConfigurator).setPoolPause(true);
    }

    function _afterSetup() internal virtual {}

    function _beforeSetup() internal virtual {}
}
