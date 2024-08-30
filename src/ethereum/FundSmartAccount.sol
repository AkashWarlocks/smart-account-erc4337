// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import {IAccount} from "lib/account-abstraction/contracts/interfaces/IAccount.sol";
import {PackedUserOperation} from "lib/account-abstraction/contracts/interfaces/PackedUserOperation.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {MessageHashUtils} from "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {SIG_VALIDATION_FAILED, SIG_VALIDATION_SUCCESS} from "lib/account-abstraction/contracts/core/Helpers.sol";
import {IEntryPoint} from "lib/account-abstraction/contracts/interfaces/IEntryPoint.sol";
import {console} from "forge-std/console.sol";

contract FundSmartAccount is IAccount, Ownable {
    address private ADMIN;
    IEntryPoint private immutable i_entrypoint;

    /** ERRORS */
    error FundSmartAccount_RequiredFromEntryPoint();
    error FundSmartAccount_RequiredFromEntryPointOrOwner();
    error FundSmartAccount_CallFailed(bytes);

    /**
     * MODIFIERS
     */
    modifier requireFromEntryPoint() {
        if (msg.sender != address(i_entrypoint)) {
            revert FundSmartAccount_RequiredFromEntryPoint();
        }
        _;
    }

    modifier requireFromEntryPointOrOwner() {
        console.log(msg.sender, owner());
        if (msg.sender != owner() && msg.sender != address(i_entrypoint)) {
            revert FundSmartAccount_RequiredFromEntryPointOrOwner();
        }
        _;
    }

    /**
     * @dev Constructor
     * @param _owner : The owner of the smart contract
     * @param _admin : The admin of the smart contract
     * @param _entrypoint : The entrypoint of the Account Abstraction Layer
     */

    constructor(
        address _owner,
        address _admin,
        address _entrypoint
    ) Ownable(_owner) {
        ADMIN = _admin;
        i_entrypoint = IEntryPoint(_entrypoint);
    }

    /**
     * ACCOUNT ABSTRACTION LAYER FUNCTIONS
     */

    function validateUserOp(
        PackedUserOperation calldata userOp,
        bytes32 userOpHash,
        uint256 missingAccountFunds
    ) external requireFromEntryPoint returns (uint256 validationData) {
        validationData = _validateSignature(userOpHash, userOp);
        _payPrefund(missingAccountFunds);
    }

    function _validateSignature(
        bytes32 userOpHash,
        PackedUserOperation calldata userOp
    ) internal view returns (uint256 validationData) {
        // Validate the signature of the user operation
        // The signature is the last 65 bytes of the user operation
        bytes32 data = MessageHashUtils.toEthSignedMessageHash(userOpHash);
        address signer = ECDSA.recover(data, userOp.signature);
        if (signer != owner()) {
            return SIG_VALIDATION_FAILED;
        }
        return SIG_VALIDATION_SUCCESS;
    }

    function _validateNonce(uint256 nonce) internal view {
        // Validate the nonce
        require(nonce == 0, "Invalid nonce");
    }

    function _payPrefund(uint256 missingAccountFunds) internal {
        // Pay the missing account funds
        // The missing account funds are transferred from the entrypoint to the smart contract
        // The entrypoint is responsible for transferring the funds to the smart contract
        // The smart contract is responsible for transferring the funds to the account
        // The account is responsible for transferring the funds to the recipient
        // The recipient is responsible for receiving the funds

        if (missingAccountFunds > 0) {
            (bool success, ) = payable(address(i_entrypoint)).call{
                value: missingAccountFunds,
                gas: type(uint256).max
            }("");
            (success);
        }
    }

    /**
     * EXTERNAL FUNCTIONS
     */

    function execute(
        address dest,
        uint256 value,
        bytes calldata data
    ) external payable requireFromEntryPointOrOwner {
        // Execute the transaction
        // The transaction is executed by the account
        // The account is responsible for executing the transaction
        // The account is responsible for transferring the funds to the recipient
        // The recipient is responsible for receiving the funds

        (bool success, bytes memory result) = dest.call{value: value}(data);
        if (!success) {
            revert FundSmartAccount_CallFailed(result);
        }
    }

    function recieve() external payable {}

    /**
     * GETTERS
     */
    function getAdmin() external view returns (address) {
        return ADMIN;
    }

    function getEntryPoint() external view returns (address) {
        return address(i_entrypoint);
    }
}
