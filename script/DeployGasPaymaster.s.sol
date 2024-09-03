// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.2;

import {Script} from "forge-std/Script.sol";
import {GasPaymaster} from "../src/ethereum/GasPaymaster.sol";
import {HelperConfig} from "./HelperConfig.s.sol";
import {IEntryPoint} from "lib/account-abstraction/contracts/interfaces/IEntryPoint.sol";

contract DeployGasPaymaster is Script {
    function run() public {}

    /**
     * To be worked on
     */
    function deployGasPaymaster(
        address entrypoint,
        address account
    ) public returns (GasPaymaster) {
        IEntryPoint entryPoint = IEntryPoint(entrypoint);
        vm.startBroadcast(account);
        GasPaymaster gasPaymaster = new GasPaymaster(entryPoint);
        vm.stopBroadcast();

        return (gasPaymaster);
    }
}
