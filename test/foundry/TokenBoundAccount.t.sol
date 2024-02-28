// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {Test, console} from "forge-std/Test.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {IERC6551Account} from "erc6551/interfaces/IERC6551Account.sol";
import {IERC6551Executable} from "erc6551/interfaces/IERC6551Executable.sol";

import {MockERC721, MockERC1155} from "../../contracts/MockNFT.sol";
import {Registry} from "../../contracts/Registry.sol";
import {TokenBoundAccount} from "../../contracts/TokenBoundAccount.sol";
import "../../contracts/NFTFactory.sol";

contract TokenBoundAccountTest is Test {
    MockERC721 public mockERC721;
    MockERC1155 public mockERC1155;
    TokenBoundAccount public implementation;
    Registry public registry;
    NFTFactory public factory;

    address public owner = makeAddr("owner");
    /* 

    function setUp() public {
        registry = deployRegistry();
        factory = deployFactory();
        mockERC721 = deployMockERC721();
        mockERC1155 = deployMockERC1155();
        implementation = new TokenBoundAccount(factory);
    }
    function testCreateAccount() public {
        setUp();
        vm.startPrank(owner);
        address account = createTBA();

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

    function testSendTransaction() external {
        vm.startPrank(owner);
        address recipient = makeAddr("recipient");
        address account = createTBA();

        IERC6551Account accountInstance = IERC6551Account(payable(account));
        IERC6551Executable executableAccountInstance = IERC6551Executable(
            account
        );
        assertEq(TokenBoundAccount(payable(account)).owner(), owner);

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

    // function testExecuteTransaction() external {
    //     address account = createTBA();
    //     address recipient = makeAddr("recipient");
    //     TokenBoundAccount tba = TokenBoundAccount(payable(account));
    //     vm.startPrank(owner);

    //     tba.execute(
    //         address(mockERC721),
    //         0 ether,
    //         abi.encodeWithSignature("safeMint(address)", address(tba)),
    //         0
    //     );
    //     assertEq(mockERC721.balanceOf(address(tba)), 1);
    //     tba.execute(
    //         address(mockERC721),
    //         0 ether,
    //         abi.encodeWithSignature(
    //             "setApprovalForAll(address,bool)",
    //             address(tba),
    //             true
    //         ),
    //         0
    //     );

    //     tba.execute(
    //         address(mockERC721),
    //         0 ether,
    //         abi.encodeWithSignature(
    //             "safeTransferFrom(address,address,uint256)",
    //             address(tba),
    //             recipient,
    //             0,
    //             ""
    //         ),
    //         0
    //     );

    //     vm.startPrank(recipient);
    //     vm.expectRevert("Invalid signer");
    //     tba.execute(
    //         address(mockERC721),
    //         0 ether,
    //         abi.encodeWithSignature("safeMint(address)", recipient),
    //         0
    //     );
    // }

    function testGetMockERC721() public {
        vm.startPrank(owner);
        address account = createTBA();

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

    function testGetMockERC1155() public {
        vm.startPrank(owner);
        address account = createTBA();

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

    function testGetTokenCounts() public {
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

    function testTransferOwnership() public {
        vm.startPrank(owner);
        address account = createTBA();
        address recipient = makeAddr("recipient");
        TokenBoundAccount tba = TokenBoundAccount(payable(account));
        assertEq(tba.owner(), owner);
        mockERC721.safeTransferFrom(owner, recipient, 0);
        assertEq(recipient, tba.owner());

        vm.deal(address(tba), 1 ether);
        vm.expectRevert("Invalid signer");
        tba.execute(payable(address(0)), 0.5 ether, "", 0);
    }

    function createTBA() public returns (address) {
        mockERC721.safeMint(owner);

        address account = registry.createAccount(
            address(implementation), //implementation
            0, //salt,
            block.chainid, //chainId,
            address(mockERC721), //tokenContract
            0 //tokenId
        );
        assertTrue(account != address(0));
        return account;
    }

    function deployFactory() public returns (NFTFactory) {
        factory = new NFTFactory();
        return factory;
    }

    function deployMockERC721() public returns (MockERC721) {
        MockERC721 nft = factory.createERC721(5);
        return nft;
    }

    function deployMockERC1155() public returns (MockERC1155) {
        MockERC1155 nft = factory.createERC1155(5);
        return nft;
    }

    function deployRegistry() public returns (Registry) {
        return new Registry();
    }
		 */
}
