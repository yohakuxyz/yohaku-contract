// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "forge-std/console.sol";

import "../contracts/Yohaku.sol";
import "../contracts//NFTFactory.sol";

contract DeployYohakuNFT is Script {
    address public minter = 0x06aa005386F53Ba7b980c61e0D067CaBc7602a62;

    function run() external {
        vm.startBroadcast();
        Yohaku yohaku = new Yohaku(minter, "QmYRmop52xSAmUC5J5squPrkyu6HtGwQc6yqQNze5q5S8v");
        console.log("Yohaku address: ", address(yohaku));
        vm.stopBroadcast();
    }
}
