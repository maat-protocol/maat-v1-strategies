// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "../utils.sol";
import {Strategy, IStrategy} from "../../contracts/Strategy.sol";
import {IERC4626} from "@openzeppelin/contracts/interfaces/IERC4626.sol";
import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";

import {MaatAddressProviderV1} from "maat-v1-core/periphery/MaatAddressProviderV1.sol";

import {DeployStrategies} from "../../script/deploy/DeployStrategies.sol";

abstract contract StrategyTestSetup is BaseTest, DeployStrategies {
    IStrategy.StrategyParams public strategyParams;

    Strategy public strategy;

    MaatAddressProviderV1 public maatAddressProvider;
    address public maatVault;

    IERC20Metadata public token;

    function asset() public view virtual returns (address) {
        return address(token);
    }

    function setUp() public virtual {
        maatAddressProvider = new MaatAddressProviderV1();
        maatAddressProvider.initialize(admin);

        // _prepareTokens();

        maatVault = createUser("tokenVault", address(this));

        vm.prank(admin);
        maatAddressProvider.addVault(maatVault);

        vm.label(address(maatVault), "TokenVault");
        vm.label(address(maatAddressProvider), "MaatAddressProvider");
    }

    /* ============ UTILS ============ */

    function _prepareTokens() internal {
        deal(address(token), maatVault, formatDecimals(100_000_000));

        token.approve(address(strategy), formatDecimals(100_000_000));
    }

    function formatDecimals(
        uint amount
    ) internal view returns (uint formattedAmount) {
        uint256 decimals = token.decimals();
        formattedAmount = amount * 10 ** decimals;
    }

    /// @notice Asserts that the balance of the token has increased by the specified amount
    /// @param addr The address to check the token balance of
    /// @param change The amount to change the balance by
    /// @dev Use negative values for balance decreases like deposit()
    /// @dev Use positive values for balance increases like withdraw()
    modifier tokenBalanceMustIncrease(address addr, uint256 change) {
        uint balanceBefore = token.balanceOf(addr);
        _;
        uint balanceAfter = token.balanceOf(addr);

        require(
            balanceAfter >= balanceBefore,
            "Expected balance to increase, but it decreased"
        );

        uint actualDelta = balanceAfter - balanceBefore;

        assertEq(
            actualDelta,
            change,
            "Test MAAT Vault token balance didn't change as expected "
        );
    }

    /// @notice Asserts that the balance of the token has decreased by the specified amount
    /// @param addr The address to check the token balance of
    /// @param change The amount to change the balance by
    /// @dev Use negative values for balance decreases like deposit()
    /// @dev Use positive values for balance increases like withdraw()
    modifier tokenBalanceMustDecrease(address addr, uint256 change) {
        uint balanceBefore = token.balanceOf(addr);
        _;
        uint balanceAfter = token.balanceOf(addr);

        require(
            balanceAfter <= balanceBefore,
            "Expected balance to decrease, but it increased"
        );

        uint actualDelta = balanceBefore - balanceAfter;

        assertEq(
            actualDelta,
            change,
            "Test MAAT Vault token balance didn't change as expected"
        );
    }

    /// @notice Asserts that the balance of the token has changed by the specified amount
    /// @param addr The address to check the token balance of
    /// @param change The amount to change the balance by
    /// @param maxExpectedError The maximum expected error in absolute value
    /// @dev Use negative values for balance decreases like deposit()
    /// @dev Use positive values for balance increases like withdraw()
    modifier tokenBalanceMustIncreaseApprox(
        address addr,
        uint change,
        uint maxExpectedError
    ) {
        uint balanceBefore = token.balanceOf(addr);
        _;
        uint balanceAfter = token.balanceOf(addr);

        require(
            balanceAfter >= balanceBefore,
            "Expected balance to increase, but it decreased"
        );

        uint actualDelta = balanceAfter - balanceBefore;

        assertApproxEqAbs(
            actualDelta,
            change,
            maxExpectedError,
            "Test MAAT Vault token balance didn't change as expected"
        );
    }

    /// @notice Asserts that the balance of the token has changed by the specified amount
    /// @param addr The address to check the token balance of
    /// @param change The amount to change the balance by
    /// @param maxExpectedError The maximum expected error in absolute value
    /// @dev Use negative values for balance decreases like deposit()
    /// @dev Use positive values for balance increases like withdraw()
    modifier tokenBalanceMustDecreaseApprox(
        address addr,
        uint change,
        uint maxExpectedError
    ) {
        uint balanceBefore = token.balanceOf(addr);
        _;
        uint balanceAfter = token.balanceOf(addr);

        require(
            balanceAfter <= balanceBefore,
            "Expected balance to decrease, but it increased"
        );

        uint actualDelta = balanceBefore - balanceAfter;

        assertApproxEqAbs(
            actualDelta,
            change,
            maxExpectedError,
            "Test MAAT Vault token balance didn't change as expected"
        );
    }
}
