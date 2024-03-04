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

    function createERC721(
        string calldata name,
        string calldata symbol,
        uint8 _basePoints
    ) public returns (MockERC721) {
        MockERC721 nft = new MockERC721(
            name,
            symbol,
            _basePoints,
            NFTFactory(address(this))
        );
        erc721s.push(nft);
        emit NFTCreated(address(nft));
        return nft;
    }

    function getERC721Points(address _owner) public view returns (uint8) {
        uint8 points;

        for (uint256 i; i < erc721s.length; i++) {
            if (erc721s[i].balanceOf(_owner) > 0) {
                points += erc721s[i].getPoints();
            }
        }
        return points;
    }

    function getContributions(
        address[] memory _owners
    ) external view returns (string[] memory) {
        // TODO: should handle the length of the array
        string[] memory tokenData = new string[](erc721s.length);
        for (uint256 n; n < _owners.length; n++) {
            for (uint256 i; i < erc721s.length; i++) {
                if (erc721s[i].balanceOf(_owners[n]) > 0) {
                    uint256 tokenId = erc721s[i].getOwnedToken(_owners[n]);
                    tokenData[i] = erc721s[i].getTokenData(tokenId).description;
                }
            }
        }
        return tokenData;
    }

    function getTotalPoints(address _addr) public view returns (uint8) {
        uint8 totalPoints = getERC721Points(_addr);
        return totalPoints;
    }

    function getCreatedERC721s() public view returns (MockERC721[] memory) {
        return erc721s;
    }
}
