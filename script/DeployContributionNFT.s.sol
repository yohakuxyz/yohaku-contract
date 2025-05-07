// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import { Script, console2 } from "forge-std/Script.sol";
import { ContributionNFT } from "../contracts/ContributionNFT.sol";
import { NFTFactory } from "../contracts/NFTFactory.sol";

contract DeployContributionNFT is Script {
    address public minter = 0x67Df9d563032dAA77273a689041bC9cFC1B35911;
    string public defaultImageUrl = "default iamge url";
    string public name = "Contribution NFT";
    string public symbol = "CNFT";
    uint8 public basePoints = 10;

    function run() external {
        vm.startBroadcast();

        bytes memory factory = vm.parseJson(vm.readFile("deployments/factory/11155111.json"), ".factory");
        address factoryAddress = abi.decode(factory, (address));
        address contributionNFT =
            address(new ContributionNFT(name, symbol, basePoints, NFTFactory(factoryAddress), defaultImageUrl, minter));
        console2.log("ContributionNFT deployed at:", contributionNFT);
        vm.stopBroadcast();
    }
}
