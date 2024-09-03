// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ISemaphore} from "@semaphore/contracts/interfaces/ISemaphore.sol";

contract Security is Ownable {
    ISemaphore private immutable semaphore;

    mapping(address => uint256) private ownerToGroup;

    /**
     * ERRORS
     */

    /**
     * EVENTS
     */

    /**
     * @dev Constructor
     * @param _semaphore : The Semaphore contract address
     */
    constructor(address _semaphore) Ownable(msg.sender) {
        semaphore = ISemaphore(_semaphore);
    }

    function createGroup(address functionOwner) public onlyOwner {
        uint256 groupId = semaphore.createGroup(owner());
        ownerToGroup[functionOwner] = groupId;
    }

    function addUserToGroup(
        address functionOwner,
        uint256 smartAccountCommittment
    ) public onlyOwner {
        uint256 groupId = ownerToGroup[functionOwner];
        semaphore.addMember(groupId, smartAccountCommittment);
    }

    /**
     * GETTERS
     */
    function getSmartAccount() public view returns (address) {
        return address(semaphore);
    }
}
