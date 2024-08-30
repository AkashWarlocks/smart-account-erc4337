// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import {Script} from "forge-std/Script.sol";
import {FundSmartAccount} from "../src/ethereum/FundSmartAccount.sol";
import {HelperConfig} from "./HelperConfig.s.sol";

contract DeployFundSmartAccount is Script {
    function run() public {}

    function deploySmartAccount()
        public
        returns (HelperConfig, FundSmartAccount)
    {
        HelperConfig helperConfig = new HelperConfig();
        HelperConfig.NetworkConfig memory config = helperConfig.getConfig();

        vm.startBroadcast(config.account);
        FundSmartAccount fundSmartAccount = new FundSmartAccount(
            config.account,
            config.account,
            config.entryPoint
        );

        vm.stopBroadcast();

        return (helperConfig, fundSmartAccount);
    }
}
