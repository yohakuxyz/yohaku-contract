// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "forge-std/Script.sol";
import "forge-std/console.sol";
import { Upgrades } from "openzeppelin-foundry-upgrades/Upgrades.sol";
import { Options } from "openzeppelin-foundry-upgrades/Options.sol";

import "../contracts/Yohaku.sol";
import "../contracts//NFTFactory.sol";

contract UpgradeYohakuNFT is Script {
    function run() external {
        string memory path = "deployments/yohaku/";

        string memory chainId = vm.toString(block.chainid);
        string memory fileName = string(abi.encodePacked(chainId, ".json"));

        bytes memory proxyAddressRaw = vm.parseJson(vm.readFile(string(abi.encodePacked(path, fileName))), ".proxy");

        address proxyAddress = abi.decode(proxyAddressRaw, (address));

        Options memory opts;

        opts.referenceContract = "Yohaku.sol";
        vm.startBroadcast();

        Upgrades.upgradeProxy(proxyAddress, "YohakuV2.sol", "", opts);

        vm.stopBroadcast();

        address implementation = Upgrades.getImplementationAddress(proxyAddress);

        console.log("Yohaku proxy address: ", proxyAddress);
        console.log("Yohaku implementation address: ", implementation);

        string memory jsonString = string(
            abi.encodePacked(
                '{"proxy": "',
                vm.toString(proxyAddress),
                '", "implementation": "',
                vm.toString(address(implementation)),
                '", "chainId": "',
                vm.toString(block.chainid),
                '"}'
            )
        );

        vm.writeFile(string(abi.encodePacked(path, fileName)), jsonString);
        console.log("Deployment addresses written to:", path);
    }
}
