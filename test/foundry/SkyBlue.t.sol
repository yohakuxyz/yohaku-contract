// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/utils/Base64.sol";

import "../../contracts/MockNFT.sol";
import "../../contracts/Registry.sol";
import "../../contracts/SkyBlue.sol";
import "../../contracts/NFTFactory.sol";

contract SkyBlueTest is Test {
    MockERC721 public mockERC721;
    SkyBlue public skyblue;
    Registry public registry;
    NFTFactory public factory;

    address public owner = makeAddr("owner");
    address public alice = makeAddr("alice");
    address public bob = makeAddr("bob");
    address public charlie = makeAddr("charlie");

    function setUp() public {
        factory = deployFactory();
        mockERC721 = deployMockERC721();

        skyblue = new SkyBlue(owner, "", factory);
    }

    function testGetBalanceOf() public {
        mintSkyblue(alice);
        assertEq(skyblue.getTotalPoint(0), 0);

        mintMockERC721(alice);
        mintMockERC721(bob);
        mintMockERC721(alice);
        mockERC721.balanceOf(alice);
        console.log(mockERC721.balanceOf(alice));
    }

    function testTokenURI() public {
        mintSkyblue(alice);
        mintSkyblue(alice);
        console.log(skyblue.tokenURI(1));
    }

    function testgetTotalPoints() public {
        // Test for ERC721
        mintSkyblue(alice);
        assertEq(skyblue.getTotalPoint(0), 0);

        mintMockERC721(alice);
        mintMockERC721(alice);
        mintMockERC721(alice);
        assertEq(mockERC721.balanceOf(alice), 3);
        assertEq(skyblue.getTotalPoint(0), 3);

        vm.prank(alice);
        skyblue.approve(address(this), 0);
        skyblue.safeTransferFrom(alice, bob, 0);

        assertEq(skyblue.getTotalPoint(0), 3);
        mintMockERC721(bob);
        mintMockERC721(bob);

        assertEq(skyblue.getTotalPoint(0), 5);
    }

    function testTransferOwnership() public {
        mintSkyblue(alice);

        vm.prank(alice);
        skyblue.approve(address(this), 0);
        skyblue.safeTransferFrom(alice, bob, 0);

        address[] memory owners = new address[](2);
        owners[0] = alice;
        owners[1] = bob;

        assertEq(skyblue.getOwners(0), owners);
        assertEq(skyblue.ownerOf(0), bob);
    }

    function testSafeMint() public {
        mintSkyblue(alice);
        assertEq(skyblue.ownerOf(0), alice);
    }

    function mintSkyblue(address to) public {
        vm.startPrank(owner);
        skyblue.safeMint(to);
        vm.stopPrank();
    }

    function mintMockERC721(address to) public {
        vm.startPrank(owner);
        mockERC721.safeMint(to, "test");
        vm.stopPrank();
    }

    function deployFactory() public returns (NFTFactory) {
        factory = new NFTFactory();
        return factory;
    }

    function deployMockERC721() public returns (MockERC721) {
        MockERC721 nft = factory.createERC721("MOCK", "MOCK", 10);
        return nft;
    }
}