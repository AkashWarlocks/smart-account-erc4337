// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.2;
import {Test} from "forge-std/Test.sol";

import {FundSmartAccount} from "../../src/ethereum/FundSmartAccount.sol";
import {DeployFundSmartAccount} from "../../script/DeployFundSmartAccount.s.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";
import {SendPackedUserOp, PackedUserOperation} from "../../script/SendPackedUserOp.s.sol";
import {IEntryPoint} from "lib/account-abstraction/contracts/interfaces/IEntryPoint.sol";
import {MessageHashUtils} from "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {ERC20Mock} from "@openzeppelin/contracts/mocks/token/ERC20Mock.sol";
import {SIG_VALIDATION_FAILED, SIG_VALIDATION_SUCCESS} from "lib/account-abstraction/contracts/core/Helpers.sol";
import {GasPaymaster} from "../../src/ethereum/GasPaymaster.sol";

contract FundSmartAccountTest is Test {
    using MessageHashUtils for bytes32;
    HelperConfig helperConfig;
    FundSmartAccount fundSmartAccount;
    ERC20Mock usdc;
    SendPackedUserOp sendPackedUserOp;
    GasPaymaster gasPaymaster;

    address randomUser = makeAddr("randomUser");

    function setUp() public {
        DeployFundSmartAccount deployFundSmartAccount = new DeployFundSmartAccount();

        (helperConfig, fundSmartAccount) = deployFundSmartAccount
            .deploySmartAccount();

        usdc = new ERC20Mock();

        sendPackedUserOp = new SendPackedUserOp();

        gasPaymaster = GasPaymaster(helperConfig.getConfig().paymaster);
    }

    // USDC approval

    function testOwnerCAnExecuteCommands() public {
        //Arrange
        assertEq(usdc.balanceOf(address(this)), 0);

        address dest = address(usdc);
        uint256 value = 0;
        bytes memory data = abi.encodeWithSelector(
            ERC20Mock.mint.selector,
            address(fundSmartAccount),
            1000
        );

        //Act
        vm.prank(fundSmartAccount.owner());

        fundSmartAccount.execute(dest, value, data);

        // Assert
        assertEq(usdc.balanceOf(address(fundSmartAccount)), 1000);
    }

    function testNonOwnerCannotExecuteCommands() public {
        assertEq(usdc.balanceOf(address(this)), 0);

        address dest = address(usdc);
        uint256 value = 0;
        bytes memory data = abi.encodeWithSelector(
            ERC20Mock.mint.selector,
            address(fundSmartAccount),
            1000
        );

        //Act
        vm.prank(randomUser);
        vm.expectRevert(
            FundSmartAccount
                .FundSmartAccount_RequiredFromEntryPointOrOwner
                .selector
        );
        fundSmartAccount.execute(dest, value, data);
    }

    function testRecoverSignedUserOp() public {
        //Arrange
        address dest = address(usdc);
        uint256 value = 0;
        bytes memory data = abi.encodeWithSelector(
            ERC20Mock.mint.selector,
            address(fundSmartAccount),
            1000
        );

        bytes memory executeCallData = abi.encodeWithSelector(
            fundSmartAccount.execute.selector,
            dest,
            value,
            data
        );

        //Act
        PackedUserOperation memory signedUserOp = sendPackedUserOp
            .generateSignedUserOp(
                executeCallData,
                helperConfig.getConfig(),
                address(fundSmartAccount)
            );

        //Assert
        bytes32 userOpHash = IEntryPoint(helperConfig.getConfig().entryPoint)
            .getUserOpHash(signedUserOp);

        address signer = ECDSA.recover(
            userOpHash.toEthSignedMessageHash(),
            signedUserOp.signature
        );

        assertEq(signer, fundSmartAccount.owner());
    }

    /**
     * 1. Sign UserOp
     * 2. Call Validate UserOp
     * 3. Assert Return is correct
     */
    function testValidationOfUsserOp() public {
        //Arrange
        address dest = address(usdc);
        uint256 value = 0;
        bytes memory data = abi.encodeWithSelector(
            ERC20Mock.mint.selector,
            address(fundSmartAccount),
            1000
        );

        bytes memory executeCallData = abi.encodeWithSelector(
            fundSmartAccount.execute.selector,
            dest,
            value,
            data
        );

        PackedUserOperation memory signedUserOp = sendPackedUserOp
            .generateSignedUserOp(
                executeCallData,
                helperConfig.getConfig(),
                address(fundSmartAccount)
            );
        bytes32 userOpHash = IEntryPoint(helperConfig.getConfig().entryPoint)
            .getUserOpHash(signedUserOp);

        //Act
        vm.prank(helperConfig.getConfig().entryPoint);
        uint256 missingAccountFunds = 0;

        uint256 validationData = fundSmartAccount.validateUserOp(
            signedUserOp,
            userOpHash,
            missingAccountFunds
        );
        //Assert
        assertEq(validationData, SIG_VALIDATION_SUCCESS, "Validation failed");
    }

    function testValidationOfUsserOpFails() public {
        //Arrange
        address dest = address(usdc);
        uint256 value = 0;
        bytes memory data = abi.encodeWithSelector(
            ERC20Mock.mint.selector,
            address(fundSmartAccount),
            1000
        );

        bytes memory executeCallData = abi.encodeWithSelector(
            fundSmartAccount.execute.selector,
            dest,
            value,
            data
        );

        PackedUserOperation memory signedUserOp = sendPackedUserOp
            .generateSignedUserOp(
                executeCallData,
                helperConfig.getConfig(),
                randomUser
            );
        bytes32 userOpHash = IEntryPoint(helperConfig.getConfig().entryPoint)
            .getUserOpHash(signedUserOp);

        //Act
        vm.prank(helperConfig.getConfig().entryPoint);
        uint256 missingAccountFunds = 0;

        uint256 validationData = fundSmartAccount.validateUserOp(
            signedUserOp,
            userOpHash,
            missingAccountFunds
        );
        //Assert
        assertEq(validationData, SIG_VALIDATION_FAILED, "Validation failed");
    }

    function testEntrypointCanExecuteCommands() public {
        address dest = address(usdc);
        uint256 value = 0;
        bytes memory data = abi.encodeWithSelector(
            ERC20Mock.mint.selector,
            address(fundSmartAccount),
            1000
        );

        bytes memory executeCallData = abi.encodeWithSelector(
            fundSmartAccount.execute.selector,
            dest,
            value,
            data
        );

        PackedUserOperation memory signedUserOp = sendPackedUserOp
            .generateSignedUserOp(
                executeCallData,
                helperConfig.getConfig(),
                address(fundSmartAccount)
            );

        vm.deal(address(fundSmartAccount), 1e18);

        //Act
        vm.prank(randomUser);
        PackedUserOperation[] memory userOps = new PackedUserOperation[](1);
        userOps[0] = signedUserOp;

        IEntryPoint(helperConfig.getConfig().entryPoint).handleOps(
            userOps,
            payable(randomUser)
        );

        assertEq(usdc.balanceOf(address(fundSmartAccount)), 1000);
    }

    function testCallsUsingPaymaster() public {
        // Arrange
        // Act
        // Revert
    }
}
