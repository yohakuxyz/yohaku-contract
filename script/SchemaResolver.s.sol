// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {Script, console2} from "forge-std/Script.sol";
import {IEAS, Attestation} from "eas-contracts/IEAS.sol";
import {ISchemaRegistry} from "eas-contracts/ISchemaRegistry.sol";

import "../contracts/AttesterResolver.sol";

contract SchemaResolverSctipt is Script {
    address minter = 0x06aa005386F53Ba7b980c61e0D067CaBc7602a62;
    ISchemaRegistry public schemaRegistry = ISchemaRegistry(0x4200000000000000000000000000000000000020);
    string schema =
        "address TokenBoundAccount,address CurrentOwner,address TokenAddress,uint256 tokenId,uint8 Score,string Description";

    function run() external {
        vm.startBroadcast();
        AttesterResolver attesterResolver =
            new AttesterResolver(IEAS(0x4200000000000000000000000000000000000021), minter);
        schemaRegistry.register(schema, attesterResolver, true);
        vm.stopBroadcast();
        console2.log("attesterResolver deployed:", address(attesterResolver));
    }
}
