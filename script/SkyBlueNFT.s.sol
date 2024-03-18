// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "forge-std/console.sol";

import "../contracts/SkyBlue.sol";
import "../contracts//NFTFactory.sol";
import "../contracts//MockNFT.sol";

contract DeploySkyBlueNFT is Script {
    address public minter = 0x06aa005386F53Ba7b980c61e0D067CaBc7602a62;

    function run() external {
        vm.startBroadcast();
        SkyBlue skyBlue = new SkyBlue(minter, "QmYRmop52xSAmUC5J5squPrkyu6HtGwQc6yqQNze5q5S8v");
        console.log("SkyBlue address: ", address(skyBlue));
        vm.stopBroadcast();
    }
}
