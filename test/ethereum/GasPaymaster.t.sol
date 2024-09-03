// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.2;
import {Test} from "forge-std/Test.sol";
import {GasPaymaster} from "../../src/ethereum/GasPaymaster.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";
import {DeployGasPaymaster} from "../../script/DeployGasPaymaster.s.sol";
import {IEntryPoint} from "lib/account-abstraction/contracts/interfaces/IEntryPoint.sol";

contract GasPaymasterTest is Test {
    GasPaymaster gasPaymaster;
    HelperConfig helperConfig;
    IEntryPoint entryPoint;
    address account;
    uint256 DEPOSIT_AMOUNT = 1e18;

    function setUp() public {
        helperConfig = new HelperConfig();
        HelperConfig.NetworkConfig memory config = helperConfig.getConfig();

        entryPoint = IEntryPoint(config.entryPoint);
        gasPaymaster = GasPaymaster(config.paymaster);
        account = config.account;
    }

    function testGasPaymaster() public {
        //Arrange
        vm.deal(address(gasPaymaster), 2e18);
        vm.deal(account, 2e18);

        // Act
        vm.startPrank(account); // Start impersonating the account
        entryPoint.depositTo{value: DEPOSIT_AMOUNT}(address(gasPaymaster));
        vm.stopPrank(); // Stop impersonating the account

        // Assert
        uint256 amount = entryPoint.balanceOf(address(gasPaymaster));

        assertEq(amount, DEPOSIT_AMOUNT);
    }
}
