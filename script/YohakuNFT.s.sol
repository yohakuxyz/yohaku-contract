// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "forge-std/console.sol";
import {Upgrades} from "openzeppelin-foundry-upgrades/Upgrades.sol";

import "../contracts/Yohaku.sol";
import "../contracts//NFTFactory.sol";

contract DeployYohakuNFT is Script {
    address public minter = 0xc3593524E2744E547f013E17E6b0776Bc27Fc614;

    function run() external {
        vm.startBroadcast();
        address proxy = Upgrades.deployTransparentProxy(
            "Yohaku.sol",
            minter,
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
