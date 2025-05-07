// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "forge-std/Script.sol";
import "forge-std/console.sol";
import { Upgrades } from "openzeppelin-foundry-upgrades/Upgrades.sol";
import { Options } from "openzeppelin-foundry-upgrades/Options.sol";

import "../contracts/Yohaku.sol";
import "../contracts//NFTFactory.sol";

contract UpgradeYohakuNFT is Script {
    // Replace with the actual proxy address
    address public proxy = 0x450CA7464E79975BA33a740fa42E36a389d65aef; //sepolia

    function run() external {
        Options memory opts;

        opts.referenceContract = "Yohaku.sol";
        vm.startBroadcast();

        Upgrades.upgradeProxy(proxy, "YohakuV2.sol", "", opts);

        vm.stopBroadcast();
    }
}
