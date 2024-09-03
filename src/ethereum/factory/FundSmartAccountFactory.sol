// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../FundSmartAccount.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract FundSmartAccountFactory is Ownable {
    event FundSmartAccountCreated(
        address indexed owner,
        address fundSmartAccount
    );

    constructor() Ownable(msg.sender) {}

    function createFundSmartAccount(
        address _owner,
        address _entryPoint,
        address _admin,
        bytes32 salt
    ) external returns (address) {
        bytes memory constructorData = abi.encode(_owner, _admin, _entryPoint);

        address fundSmartAccountAddress = deploy(constructorData, salt);
        emit FundSmartAccountCreated(msg.sender, fundSmartAccountAddress);
        return fundSmartAccountAddress;
    }

    function deploy(
        bytes memory functionData,
        bytes32 salt
    ) internal returns (address) {
        address addr;
        bytes memory bytecode = abi.encodePacked(
            type(FundSmartAccount).creationCode,
            functionData
        );
        assembly {
            addr := create2(0, add(bytecode, 0x20), mload(bytecode), salt)
            if iszero(extcodesize(addr)) {
                revert(0, 0)
            }
        }
        return addr;
    }

    function getAddress(
        address _owner,
        address _entryPoint,
        address _admin,
        bytes32 salt
    ) external view returns (address) {
        bytes memory constructorData = abi.encode(_owner, _admin, _entryPoint);

        bytes memory bytecode = abi.encodePacked(
            type(FundSmartAccount).creationCode,
            constructorData
        );

        bytes32 hash = keccak256(
            abi.encodePacked(
                bytes1(0xff),
                address(this),
                salt,
                keccak256(bytecode)
            )
        );
        return address(uint160(uint(hash)));
    }
}
