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

    address public currentPrankee;
    address public owner = makeAddr("owner");
    address public alice = makeAddr("alice");
    address public bob = makeAddr("bob");
    address public charlie = makeAddr("charlie");

    function setUp() public {
        factory = deployFactory();
        mockERC721 = deployMockERC721();

        skyblue = new SkyBlue(owner, "");
    }

    function testTokenURI() public {
        mintSkyblue(alice);
        console.log(skyblue.tokenURI(0));
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

    function mintSkyblue(address to) public prankception(owner) {
        skyblue.mintWithMetaData(to, "SkyblueNFT represent proof of contributions", "");
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

    modifier prankception(address prankee) {
        address prankBefore = currentPrankee;
        vm.stopPrank();
        vm.startPrank(prankee);
        _;
        vm.stopPrank();
        if (prankBefore != address(0)) {
            vm.startPrank(prankBefore);
        }
    }
}
