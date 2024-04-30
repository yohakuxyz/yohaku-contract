// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/utils/Base64.sol";

import "../../contracts/Yohaku.sol";

contract YohakuTest is Test {
    Yohaku public yohaku;

    address public currentPrankee;
    address public owner = makeAddr("owner");
    address public alice = makeAddr("alice");
    address public bob = makeAddr("bob");
    address public charlie = makeAddr("charlie");

    function setUp() public {
        yohaku = new Yohaku(owner, "");
    }

    function testTokenURI() public {
        mintYohaku(alice);
        console.log(yohaku.tokenURI(0));
    }

    function testTransferOwnership() public {
        mintYohaku(alice);

        vm.prank(alice);
        yohaku.approve(address(this), 0);
        yohaku.safeTransferFrom(alice, bob, 0);

        address[] memory owners = new address[](2);
        owners[0] = alice;
        owners[1] = bob;

        assertEq(yohaku.getOwners(0), owners);
        assertEq(yohaku.ownerOf(0), bob);
    }

    function testSafeMint() public {
        mintYohaku(alice);
        assertEq(yohaku.ownerOf(0), alice);
    }

    function mintYohaku(address to) public prankception(owner) {
        yohaku.mintWithMetaData(to, "YohakuNFT represent proof of contributions", "");
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
