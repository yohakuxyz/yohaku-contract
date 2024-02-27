// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./MockNFT.sol";

contract NFTFactory {
    MockERC721[] public erc721s;
    MockERC1155[] public erc1155s;

    event NFTCreated(address nftAddress);

    function createERC721(uint8 _points) public returns (address) {
        MockERC721 nft = new MockERC721(_points);
        erc721s.push(nft);
        emit NFTCreated(address(nft));
        return address(nft);
    }

    function createERC1155(uint8 _points) public returns (address) {
        MockERC1155 nft = new MockERC1155(_points);
        erc1155s.push(nft);
        emit NFTCreated(address(nft));
        return address(nft);
    }

    function getTotalPoints(address _addr) public view returns (uint8) {
        uint8 totalPoints = 0;
        for (uint8 i = 0; i < erc721s.length; i++) {
            erc721s[i].balanceOf(_addr) > 0
                ? totalPoints += erc721s[i].getPoinst()
                : 0;
        }
        for (uint8 i = 0; i < erc1155s.length; i++) {
            uint256 _totalSupply = erc1155s[i].totalSupply();
            for (uint256 j = 0; j < _totalSupply; j++) {
                erc1155s[i].balanceOf(_addr, j) > 0
                    ? totalPoints += erc1155s[i].getPoinst()
                    : 0;
            }
        }

        return totalPoints;
    }
}
