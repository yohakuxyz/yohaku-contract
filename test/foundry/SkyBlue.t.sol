// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/utils/Base64.sol";

import "../../contracts/SkyBlue.sol";

contract SkyBlueTest is Test {
    SkyBlue public skyblue;

    address public currentPrankee;
    address public owner = makeAddr("owner");
    address public alice = makeAddr("alice");
    address public bob = makeAddr("bob");
    address public charlie = makeAddr("charlie");

    function setUp() public {
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
