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
        Yohaku yohaku = Yohaku(proxy);
        console.log("Yohaku address: ", address(yohaku));
        vm.stopBroadcast();
    }
}
