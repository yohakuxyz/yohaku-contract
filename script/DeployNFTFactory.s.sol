// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import { Script, console2 } from "forge-std/Script.sol";
import { ISchemaRegistry } from "eas-contracts/ISchemaRegistry.sol";
import { IEAS } from "eas-contracts/IEAS.sol";
import { NFTFactory } from "../contracts/NFTFactory.sol";

contract DeployNFTFactory is Script {
    address public owner = 0x67Df9d563032dAA77273a689041bC9cFC1B35911;
    IEAS public eas;
    ISchemaRegistry public schemaRegistry;

    function _configureChain() internal {
        if (block.chainid == 10) {
            // optimism
            eas = IEAS(0x4200000000000000000000000000000000000021);
            schemaRegistry = ISchemaRegistry(0x4200000000000000000000000000000000000020);
        } else if (block.chainid == 11_155_111) {
            // sepolia
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
        console2.log("factory deployed:", address(factory));
        vm.stopBroadcast();

        string memory path = "deployments/factory/";
        string memory fileName = string(abi.encodePacked(vm.toString(block.chainid), ".json"));
        string memory filePath = string(abi.encodePacked(path, fileName));

        string memory jsonString = string(
            abi.encodePacked(
                '{"factory": "',
                vm.toString(address(factory)),
                '", "chainId": "',
                vm.toString(block.chainid),
                '", "owner": "',
                vm.toString(owner),
                '"}'
            )
        );

        vm.writeFile(filePath, jsonString);
        console2.log("Deployment addresses written to:", path);
    }
}
