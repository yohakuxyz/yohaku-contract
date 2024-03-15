// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script, console2} from "forge-std/Script.sol";
import {ISchemaRegistry} from "eas-contracts/ISchemaRegistry.sol";
import {IEAS} from "eas-contracts/IEAS.sol";
import "../contracts/NFTFactory.sol";

contract DeployNFTFactory is Script {
    address public owner = 0x06aa005386F53Ba7b980c61e0D067CaBc7602a62;
    IEAS eas = IEAS(0xaEF4103A04090071165F78D45D83A0C0782c2B2a);
    ISchemaRegistry schemaRegistry = ISchemaRegistry(0x55D26f9ae0203EF95494AE4C170eD35f4Cf77797);

    function run() external {
        vm.startBroadcast();
        NFTFactory factory = new NFTFactory(owner, eas, schemaRegistry);
        vm.stopBroadcast();
        console2.log("factory deployed:", address(factory));
    }
}
