// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {Script, console2} from "forge-std/Script.sol";

import "../contracts/SkyBlue.sol";
import "../contracts/Registry.sol";
import "../contracts/TokenBoundAccount.sol";
import "../contracts/NFTFactory.sol";

// // forge script script/TokenBoundAccount.s.sol:TokenBoundAccountSctipt --rpc-url https://optimism-goerli.infura.io/v3/APIkey --broadcast -vvvv --private-key PrivateKey --etherscan-api-key APIkey --verify
contract TokenBoundAccountSctipt is Script {
    address public owner = 0x06aa005386F53Ba7b980c61e0D067CaBc7602a62;
    uint256 public TOKEN_ID = 1;
    NFTFactory public factory;

    function run() external returns (address) {
        vm.startBroadcast();
        factory = new NFTFactory();
        Registry registry = new Registry();
        SkyBlue skyblue = new SkyBlue(owner, "ipfs://bafkreidp6xswfzex5mr6akr7azn3e4rza57ukuxyo2tq6slymliaeuenoi");
        TokenBoundAccount implementation = new TokenBoundAccount();
        skyblue.safeMint(owner);
        address account = registry.createAccount(address(implementation), 0, block.chainid, address(skyblue), 0);
        TokenBoundAccount accountInstance = TokenBoundAccount(payable(account));
        vm.stopBroadcast();
        return address(accountInstance);
    }
}
