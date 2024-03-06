// SPDX-License-Identifier: MIT
// Compatible with OpenZeppelin Contracts ^5.0.0
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "forge-std/console.sol";

import "../contracts/SkyBlue.sol";
import "../contracts//NFTFactory.sol";
import "../contracts//MockNFT.sol";

contract DeploySkyBlueNFT is Script {
    address public owner = msg.sender;

    function run() external {
        NFTFactory nftFactory = new NFTFactory();
        SkyBlue skyBlue = new SkyBlue(owner, "https://example.com", nftFactory);
        console.log("SkyBlue address: ", address(skyBlue));
    }
}
