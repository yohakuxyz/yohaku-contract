// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {Script, console2} from "forge-std/Script.sol";

import {MockERC721, MockERC1155} from "../contracts/MockNFT.sol";
import {Registry} from "../contracts/Registry.sol";
import {TokenBoundAccount} from "../contracts/TokenBoundAccount.sol";

// // forge script script/TokenBoundAccount.s.sol:TokenBoundAccountSctipt --rpc-url https://optimism-goerli.infura.io/v3/APIkey --broadcast -vvvv --private-key PrivateKey --etherscan-api-key APIkey --verify
contract TokenBoundAccountSctipt is Script {
    uint256 deployerPrivateKey = vm.envUint("DEPLOYER_PRIVATE_KEY");

    address public owner;
    address public constant ERC721_CONTRACT =
        0x6eE3aD827EbfCc12F14DC61DCDF5CeE88395b51A;
    uint256 public constant TOKEN_ID = 1;

    function run() external returns (address) {
        vm.startBroadcast();
        // MockERC721 mockERC721 = new MockERC721();
        Registry registry = new Registry();
        TokenBoundAccount implementation = new TokenBoundAccount();
        address account = registry.createAccount(
            address(implementation),
            0,
            block.chainid,
            ERC721_CONTRACT,
            0
        );
        TokenBoundAccount accountInstance = TokenBoundAccount(payable(account));
        vm.stopBroadcast();
        return address(accountInstance);
    }
}
