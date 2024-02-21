// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import {LicenceNFT} from "../../contracts/LicenceNFT.sol";
import {Registry} from "../../contracts/Registry.sol";

contract TokenBoundAccountTest is Test {
    LicenceNFT public licenceNFT;
    Registry public registry;
    address public owner;
    function setUp() public {
        owner = makeAddr("owner");
        licenceNFT = deployLicenceNFT(owner);
        registry = deployRegistry();
    }

    function test_createAccount() public {
        setUp();
        vm.startPrank(owner);
        licenceNFT.safeMint(owner, "");

        address account = registry.createAccount(
            address(0), //implementation
            0, //salt,
            0, //chainId,
            address(licenceNFT), //tokenContract
            0 //tokenId
        );

        assertEq(
            account,
            registry.account(
                address(0), //implementation
                0, //salt,
                0, //chainId,
                address(licenceNFT), //tokenContract
                0 //tokenId
            )
        );
    }

    function deployLicenceNFT(address _owner) public returns (LicenceNFT) {
        return new LicenceNFT(_owner);
    }
    function deployRegistry() public returns (Registry) {
        return new Registry();
    }
}
