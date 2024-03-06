// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./MockNFT.sol";

contract NFTFactory {
    MockERC721[] public erc721s;

    event NFTCreated(address nftAddress);

    // owner => tokenAddress => tokenIds
    mapping(address => mapping(address => uint256[])) private _ownedTokens;

    function createERC721(string calldata name, string calldata symbol, uint8 _basePoints)
        public
        returns (MockERC721)
    {
        MockERC721 nft = new MockERC721(name, symbol, _basePoints, NFTFactory(address(this)));
        erc721s.push(nft);
        emit NFTCreated(address(nft));
        return nft;
    }

    function getCreatedERC721s() public view returns (MockERC721[] memory) {
        return erc721s;
    }
}
