// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {Script, console2} from "forge-std/Script.sol";
import {ISchemaRegistry} from "eas-contracts/ISchemaRegistry.sol";
import {IEAS} from "eas-contracts/IEAS.sol";
import "../contracts/Yohaku.sol";
import "../contracts/Registry.sol";
import "../contracts/TokenBoundAccount.sol";
import "../contracts/NFTFactory.sol";

// forge script script/TokenBoundAccount.s.sol:TokenBoundAccountSctipt --rpc-url $OPTIMISM_SEPOLIA_RPC_URL --broadcast -vvvv --private-key $DEPLOYER_PRIVATE_KEY --etherscan-api-key $API_KEY_OPTIMISTIC_ETHERSCAN --verify
contract TokenBoundAccountSctipt is Script {
    // mumbai
    address public owner = 0x06aa005386F53Ba7b980c61e0D067CaBc7602a62;
    IEAS eas = IEAS(0xaEF4103A04090071165F78D45D83A0C0782c2B2a);
    ISchemaRegistry schemaRegistry = ISchemaRegistry(0x55D26f9ae0203EF95494AE4C170eD35f4Cf77797);

    NFTFactory public factory;

    function run() external {
        vm.startBroadcast();
        factory = new NFTFactory(owner, eas, schemaRegistry);
        Registry registry = new Registry();
        Yohaku yohaku = new Yohaku(owner, "Yohaku", "QmYRmop52xSAmUC5J5squPrkyu6HtGwQc6yqQNze5q5S8v");
        TokenBoundAccount implementation = new TokenBoundAccount();
        vm.stopBroadcast();

        console2.log("registry deployed:", address(registry));
        console2.log("yohaku deployed:", address(yohaku));
        console2.log("factory deployed:", address(factory));
        console2.log("implementation deployed:", address(implementation));
    }
}
