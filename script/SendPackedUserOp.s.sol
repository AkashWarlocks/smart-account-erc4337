// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {Script} from "forge-std/Script.sol";
import {PackedUserOperation} from "lib/account-abstraction/contracts/interfaces/PackedUserOperation.sol";

import {HelperConfig} from "./HelperConfig.s.sol";
import {IEntryPoint} from "lib/account-abstraction/contracts/interfaces/IEntryPoint.sol";
import {MessageHashUtils} from "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";

contract SendPackedUserOp is Script {
    using MessageHashUtils for bytes32;

    function run() public {}

    function generateSignedUserOp(
        bytes memory callData,
        HelperConfig.NetworkConfig memory config,
        address smartAccount
    ) public view returns (PackedUserOperation memory) {
        uint256 nonce = vm.getNonce(smartAccount) - 1;
        // 1. Generate unsiged userOP
        PackedUserOperation memory userOp = _generateUnsignedUserOp(
            callData,
            smartAccount,
            nonce,
            config.paymaster
        );
        // get userOp Hash

        bytes32 userOpHash = IEntryPoint(config.entryPoint).getUserOpHash(
            userOp
        );
        // 2. Sign the userOP
        bytes32 digest = userOpHash.toEthSignedMessageHash();
        uint8 v;
        bytes32 r;
        bytes32 s;
        uint256 AVNIL_DEFAULT_KEY = 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80;

        // 3. Return the signed userOP
        if (block.chainid == 31337) {
            (v, r, s) = vm.sign(AVNIL_DEFAULT_KEY, digest);
        } else {
            (v, r, s) = vm.sign(config.account, digest);
        }

        userOp.signature = abi.encodePacked(r, s, v);

        return userOp;
    }

    function _generateUnsignedUserOp(
        bytes memory callData,
        address sender,
        uint256 nonce,
        address paymaster
    ) internal pure returns (PackedUserOperation memory) {
        // 1. Generate unsiged userOP
        // 2. Return the unsigned userOP
        uint128 verificationGasLimit = 16777216;
        uint128 callGasLimit = verificationGasLimit;
        uint128 maxPriorityFeePerGas = 256;
        uint128 maxFeePerGas = maxPriorityFeePerGas;

        bytes memory paymasterAndData;

        if (paymaster != address(0)) {
            paymasterAndData = _generatePaymasterData(
                paymaster,
                verificationGasLimit,
                callGasLimit
            );
        } else {
            paymasterAndData = hex"";
        }
        return
            PackedUserOperation({
                sender: sender,
                nonce: nonce,
                initCode: hex"",
                callData: callData,
                accountGasLimits: bytes32(
                    (uint256(verificationGasLimit) << 128) | callGasLimit
                ),
                preVerificationGas: verificationGasLimit,
                gasFees: bytes32(
                    (uint256(maxPriorityFeePerGas) << 128) | maxFeePerGas
                ),
                paymasterAndData: hex"",
                signature: hex""
            });
    }

    function _generatePaymasterData(
        address _paymaster,
        uint128 validationGaslimit,
        uint128 postOpGasLimit
    ) internal pure returns (bytes memory) {
        return abi.encodePacked(_paymaster, validationGaslimit, postOpGasLimit);
    }
}
