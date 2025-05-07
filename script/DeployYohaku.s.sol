// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "forge-std/Script.sol";
import "forge-std/console.sol";
import { Upgrades } from "openzeppelin-foundry-upgrades/Upgrades.sol";

import "../contracts/Yohaku.sol";
import "../contracts//NFTFactory.sol";

contract DeployYohakuNFT is Script {
    address public minter = 0x67Df9d563032dAA77273a689041bC9cFC1B35911;

    function run() external {
        vm.startBroadcast();
        address proxy = Upgrades.deployUUPSProxy(
            "Yohaku.sol",
            abi.encodeCall(
                Yohaku.initialize,
                (
                    minter,
                    "[](yohaku) is a project aimed at improving communities and the connections among the people involved.",
                    "QmdhG2em4KmD4JzBh1goY18GsGNiSQucgSHpHqZxPS6Wns"
                )
            )
        );
        address implementation = Upgrades.getImplementationAddress(proxy);

        console.log("Yohaku proxy address: ", proxy);
        console.log("Yohaku implementation address: ", implementation);
        string memory path = "deployments/yohaku/";
        string memory fileName = string(abi.encodePacked(vm.toString(block.chainid), ".json"));
        string memory filePath = string(abi.encodePacked(path, fileName));

        string memory jsonString = string(
            abi.encodePacked(
                '{"proxy": "',
                vm.toString(proxy),
                '", "implementation": "',
                vm.toString(address(implementation)),
                '", "chainId": "',
                vm.toString(block.chainid),
                '"}'
            )
        );

        vm.stopBroadcast();
        vm.writeFile(filePath, jsonString);
        console.log("Deployment addresses written to:", path);
    }
}
