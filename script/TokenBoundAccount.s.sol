// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {Script, console2} from "forge-std/Script.sol";

import "../contracts/SkyBlue.sol";
import "../contracts/Registry.sol";
import "../contracts/TokenBoundAccount.sol";
import "../contracts/NFTFactory.sol";

// forge script script/TokenBoundAccount.s.sol:TokenBoundAccountSctipt --rpc-url $OPTIMISM_SEPOLIA_RPC_URL --broadcast -vvvv --private-key $DEPLOYER_PRIVATE_KEY --etherscan-api-key $API_KEY_OPTIMISTIC_ETHERSCAN --verify
contract TokenBoundAccountSctipt is Script {
    address public owner = 0x06aa005386F53Ba7b980c61e0D067CaBc7602a62;
    
    NFTFactory public factory;

    function run() external {
        vm.startBroadcast();
        factory = new NFTFactory();
        Registry registry = new Registry();
        SkyBlue skyblue = new SkyBlue(owner, "QmYRmop52xSAmUC5J5squPrkyu6HtGwQc6yqQNze5q5S8v");
        TokenBoundAccount implementation = new TokenBoundAccount();
        vm.stopBroadcast();

        console2.log("registry deployed:", address(registry));
        console2.log("skyblue deployed:", address(skyblue));
        console2.log("factory deployed:", address(factory));
        console2.log("implementation deployed:", address(implementation));
    }
}
