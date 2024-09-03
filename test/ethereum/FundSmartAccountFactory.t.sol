// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "../../src/ethereum/factory/FundSmartAccountFactory.sol";
import "../../src/ethereum/FundSmartAccount.sol";
import "../../script/HelperConfig.s.sol";
import "../../src/ethereum/FundSmartAccount.sol";
import "../../script/DeployFundSmartAccoutFactory.s.sol";

contract FundSmartAccountFactoryTest is Test {
    FundSmartAccountFactory factory;
    address owner = address(0x123);
    address entryPoint = address(0x456);
    address admin = address(0x789);
    bytes32 salt = keccak256(abi.encodePacked("test_salt"));

    HelperConfig helperConfig;

    event FundSmartAccountCreated(
        address indexed creator,
        address indexed fundSmartAccountAddress
    );

    function setUp() public {
        DeployFundSmartAccountFactory deployFundSmartAccountFactory = new DeployFundSmartAccountFactory();
        (helperConfig, factory) = deployFundSmartAccountFactory
            .deploySmartAccountFactory();
    }

    function testCreateFundSmartAccount() public {
        HelperConfig.NetworkConfig memory config = helperConfig.getConfig();

        // Act
        address fundSmartAccountAddress = factory.createFundSmartAccount(
            config.account,
            config.entryPoint,
            config.account,
            salt
        );

        // Get instance of FundSmartAccount

        FundSmartAccount fundSmartAccount = FundSmartAccount(
            fundSmartAccountAddress
        );

        // Assert
        assertEq(fundSmartAccount.owner(), config.account);
    }

    function testCreateAccountAndGetAddress() public {
        HelperConfig.NetworkConfig memory config = helperConfig.getConfig();

        // Act
        address fundSmartAccountAddress = factory.createFundSmartAccount(
            config.account,
            config.entryPoint,
            config.account,
            salt
        );

        // Get instance of FundSmartAccount

        address derivedAddress = factory.getAddress(
            config.account,
            config.entryPoint,
            config.account,
            salt
        );

        // Assert
        assertEq(derivedAddress, fundSmartAccountAddress);
    }
}
