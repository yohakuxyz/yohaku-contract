// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {Test, console} from "forge-std/Test.sol";

import {MockERC721, MockERC1155} from "../../contracts/MockNFT.sol";
import {Registry} from "../../contracts/Registry.sol";
import {TokenBoundAccount} from "../../contracts/TokenBoundAccount.sol";
import {IERC721} from "openzeppelin/contracts/token/ERC721/IERC721.sol";
import {IERC6551Account} from "erc6551/interfaces/IERC6551Account.sol";
import {IERC6551Executable} from "erc6551/interfaces/IERC6551Executable.sol";

contract TokenBoundAccountTest is Test {
    MockERC721 public mockERC721;
    MockERC1155 public mockERC1155;
    TokenBoundAccount public implementation;
    Registry public registry;
    address owner = makeAddr("owner");
    function setUp() public {
        mockERC721 = deployMockERC721();
        mockERC1155 = deployMockERC1155();
        registry = deployRegistry();
        implementation = new TokenBoundAccount();
    }

    function test_createAccount() public {
        setUp();
        vm.startPrank(owner);
        mockERC721.safeMint(owner);

        address account = registry.createAccount(
            address(implementation), //implementation
            0, //salt,
            block.chainid, //chainId,
            address(mockERC721), //tokenContract
            0 //tokenId
        );

        assertEq(
            account,
            registry.account(
                address(implementation), //implementation
                0, //salt,
                block.chainid, //chainId,
                address(mockERC721), //tokenContract
                0 //tokenId
            )
        );
    }

    function test_sendTransaction() external {
        vm.startPrank(owner);
        address recipient = makeAddr("recipient");
        mockERC721.safeMint(owner);
        address account = registry.createAccount(
            address(implementation), //implementation
            0, //salt,
            block.chainid, //chainId,
            address(mockERC721), //tokenContract
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

    function test_getMockERC721() public {
        vm.startPrank(owner);
        mockERC721.safeMint(owner);
        address account = registry.createAccount(
            address(implementation), //implementation
            0, //salt,
            block.chainid, //chainId,
            address(mockERC721), //tokenContract
            0 //tokenId
        );

        TokenBoundAccount tba = TokenBoundAccount(payable(account));
        mockERC721.safeMint(address(tba));
        mockERC721.safeMint(address(tba));

        TokenBoundAccount.Token memory tokenInfo = TokenBoundAccount.Token(
            address(mockERC721),
            0, // just set to 0 for ERC721
            TokenBoundAccount.TokenType.ERC721
        );
        assertEq(tba.getTokenBalance(tokenInfo), 2);
    }
    function test_getMockERC1155() public {
        vm.startPrank(owner);
        mockERC721.safeMint(owner);
        address account = registry.createAccount(
            address(implementation), //implementation
            0, //salt,
            block.chainid, //chainId,
            address(mockERC721), //tokenContract
            0 //tokenId
        );

        TokenBoundAccount tba = TokenBoundAccount(payable(account));
        mockERC1155.mint(address(tba), 0, 2, "");
        TokenBoundAccount.Token memory tokenInfo = TokenBoundAccount.Token(
            address(mockERC1155),
            0, // just set to 0 for ERC721
            TokenBoundAccount.TokenType.ERC1155
        );
        assertEq(MockERC1155(mockERC1155).balanceOf(address(tba), 0), 2);
        assertEq(tba.getTokenBalance(tokenInfo), 2);
    }

    function test_getTokenCounts() public {
        vm.startPrank(owner);
        address account = createTBA();
        TokenBoundAccount tba = TokenBoundAccount(payable(account));
        mockERC721.safeMint(address(tba));
        mockERC721.safeMint(address(tba));
        mockERC1155.mint(address(tba), 0, 2, "");

        TokenBoundAccount.Token[] memory tokens = new TokenBoundAccount.Token[](
            2
        );
        tokens[0] = TokenBoundAccount.Token(
            address(mockERC721),
            0,
            TokenBoundAccount.TokenType.ERC721
        );
        tokens[1] = TokenBoundAccount.Token(
            address(mockERC1155),
            0,
            TokenBoundAccount.TokenType.ERC1155
        );

        assertEq(tba.getTokenCounts(tokens), 4);
    }

    function createTBA() public returns (address) {
        address account = registry.createAccount(
            address(implementation), //implementation
            0, //salt,
            block.chainid, //chainId,
            address(mockERC721), //tokenContract
            0 //tokenId
        );
        return account;
    }

    function deployMockERC721() public returns (MockERC721) {
        return new MockERC721();
    }
    function deployMockERC1155() public returns (MockERC1155) {
        return new MockERC1155();
    }
    function deployRegistry() public returns (Registry) {
        return new Registry();
    }
}
