// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {Test, console} from "forge-std/Test.sol";

import {LicenceNFT} from "../../contracts/LicenceNFT.sol";
import {Registry} from "../../contracts/Registry.sol";
import {TokenBoundAccount} from "../../contracts/TokenBoundAccount.sol";
import {IERC721} from "openzeppelin/contracts/token/ERC721/IERC721.sol";
import {IERC6551Account} from "erc6551/interfaces/IERC6551Account.sol";
import {IERC6551Executable} from "erc6551/interfaces/IERC6551Executable.sol";

contract TokenBoundAccountTest is Test {
    LicenceNFT public licenceNFT;
    TokenBoundAccount public implementation;
    Registry public registry;
    address owner = makeAddr("owner");
    function setUp() public {
        licenceNFT = deployLicenceNFT();
        registry = deployRegistry();
        implementation = new TokenBoundAccount();
    }

    function test_createAccount() public {
        setUp();
        vm.startPrank(owner);
        licenceNFT.safeMint(owner);

        address account = registry.createAccount(
            address(implementation), //implementation
            0, //salt,
            block.chainid, //chainId,
            address(licenceNFT), //tokenContract
            0 //tokenId
        );

        assertEq(
            account,
            registry.account(
                address(implementation), //implementation
                0, //salt,
                block.chainid, //chainId,
                address(licenceNFT), //tokenContract
                0 //tokenId
            )
        );
    }

    function test_sendTransaction() external {
        vm.startPrank(owner);
        address recipient = makeAddr("recipient");
        licenceNFT.safeMint(owner);
        address account = registry.createAccount(
            address(implementation), //implementation
            0, //salt,
            block.chainid, //chainId,
            address(licenceNFT), //tokenContract
            0 //tokenId
        );
        assertTrue(account != address(0));

        IERC6551Account accountInstance = IERC6551Account(payable(account));
        IERC6551Executable executableAccountInstance = IERC6551Executable(
            account
        );

        address ownerAccount = TokenBoundAccount(payable(account)).owner();
        assertEq(ownerAccount, owner);

        assertEq(
            accountInstance.isValidSigner(owner, ""),
            IERC6551Account.isValidSigner.selector
        );
        vm.deal(account, 1 ether);
        executableAccountInstance.execute(payable(recipient), 0.5 ether, "", 0);
        assertEq(account.balance, 0.5 ether);
        assertEq(recipient.balance, 0.5 ether);
        assertEq(accountInstance.state(), 1);
    }

    function deployLicenceNFT() public returns (LicenceNFT) {
        return new LicenceNFT();
    }
    function deployRegistry() public returns (Registry) {
        return new Registry();
    }
}
