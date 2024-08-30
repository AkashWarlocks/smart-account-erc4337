// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {Script, console2} from "forge-std/Script.sol";
import {EntryPoint} from "lib/account-abstraction/contracts/core/EntryPoint.sol";

contract HelperConfig is Script {
    error HelperConfig_InvalidConfig();

    struct NetworkConfig {
        address entryPoint;
        address account;
    }

    uint256 constant ETH_SEPOLIA_CHAIN_ID = 11155111;
    uint256 constant POLY_AMOY_CHAIN_ID = 80002;
    uint256 constant LOCAL_CHAIN_ID = 31337;
    address constant BURNER_ADDRESS =
        0xFB62886F274aDBa10797B1B67810A47F8Ecb632A;

    address internal constant SENDER_ADDRES_DEFAULT =
        0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266;

    mapping(uint256 chainId => NetworkConfig) public networkConfig;
    NetworkConfig public localConfig;

    constructor() {
        networkConfig[ETH_SEPOLIA_CHAIN_ID] = getEthSepoliaConfig();
        networkConfig[POLY_AMOY_CHAIN_ID] = getPolyAmoyConfig();
    }

    function getConfig() public returns (NetworkConfig memory) {
        return getConfigByChainId(block.chainid);
    }

    function getConfigByChainId(
        uint256 chainId
    ) public returns (NetworkConfig memory) {
        if (chainId == LOCAL_CHAIN_ID) {
            return getOrCreateLocalConfig();
        } else if (networkConfig[chainId].entryPoint != address(0)) {
            return networkConfig[chainId];
        } else {
            revert HelperConfig_InvalidConfig();
        }
    }

    function getEthSepoliaConfig()
        internal
        pure
        returns (NetworkConfig memory)
    {
        return
            NetworkConfig({
                entryPoint: 0x5FF137D4b0FDCD49DcA30c7CF57E578a026d2789,
                account: BURNER_ADDRESS
            });
    }

    function getPolyAmoyConfig() internal pure returns (NetworkConfig memory) {
        return
            NetworkConfig({
                entryPoint: 0x5FF137D4b0FDCD49DcA30c7CF57E578a026d2789,
                account: BURNER_ADDRESS
            });
    }

    function getOrCreateLocalConfig() internal returns (NetworkConfig memory) {
        if (localConfig.entryPoint != address(0)) {
            return localConfig;
        }

        // Deploy mocks
        console2.log("Deploying mocks");

        vm.startBroadcast(DEFAULT_SENDER);

        EntryPoint entryPoint = new EntryPoint();

        vm.stopBroadcast();
        localConfig = NetworkConfig({
            entryPoint: address(entryPoint),
            account: SENDER_ADDRES_DEFAULT
        });
        return localConfig;
    }
}
