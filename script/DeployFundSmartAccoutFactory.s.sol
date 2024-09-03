// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import {Script} from "forge-std/Script.sol";
import {FundSmartAccount} from "../src/ethereum/FundSmartAccount.sol";
import {HelperConfig} from "./HelperConfig.s.sol";
import {FundSmartAccountFactory} from "../src/ethereum/factory/FundSmartAccountFactory.sol";

contract DeployFundSmartAccountFactory is Script {
    function run() public {}

    function deploySmartAccountFactory()
        public
        returns (HelperConfig, FundSmartAccountFactory)
    {
        HelperConfig helperConfig = new HelperConfig();
        HelperConfig.NetworkConfig memory config = helperConfig.getConfig();

        vm.startBroadcast(config.account);
        FundSmartAccountFactory fundSmartAccountFactory = new FundSmartAccountFactory();

        vm.stopBroadcast();

        return (helperConfig, fundSmartAccountFactory);
    }
}
