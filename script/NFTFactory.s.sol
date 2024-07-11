// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script, console2} from "forge-std/Script.sol";
import {ISchemaRegistry} from "eas-contracts/ISchemaRegistry.sol";
import {IEAS} from "eas-contracts/IEAS.sol";
import "../contracts/NFTFactory.sol";

contract DeployNFTFactory is Script {
    address public owner = 0xc3593524E2744E547f013E17E6b0776Bc27Fc614;
    IEAS public eas;
    ISchemaRegistry public schemaRegistry;

    function _configureChain() internal {
        if (block.chainid == 80001) {
            eas = IEAS(0xaEF4103A04090071165F78D45D83A0C0782c2B2a);
            schemaRegistry = ISchemaRegistry(0x55D26f9ae0203EF95494AE4C170eD35f4Cf77797);
        } else if (block.chainid == 137) {
            eas = IEAS(0x5E634ef5355f45A855d02D66eCD687b1502AF790);
            schemaRegistry = ISchemaRegistry(0x7876EEF51A891E737AF8ba5A5E0f0Fd29073D5a7);
        } else if (block.chainid == 10) {
            eas = IEAS(0x4200000000000000000000000000000000000021);
            schemaRegistry = ISchemaRegistry(0x4200000000000000000000000000000000000020);
        } else if (block.chainid == 11155111) {
            eas = IEAS(0xC2679fBD37d54388Ce493F1DB75320D236e1815e);
            schemaRegistry = ISchemaRegistry(0x0a7E2Ff54e76B8E6659aedc9103FB21c038050D0);
        } else {
            revert("Unsupported chain");
        }
    }

    function run() external {
        _configureChain();
        vm.startBroadcast();
        NFTFactory factory = new NFTFactory(owner, eas, schemaRegistry);
        vm.stopBroadcast();
        console2.log("factory deployed:", address(factory));
    }
}
