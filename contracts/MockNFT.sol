// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Base64.sol";
import "./NFTFactory.sol";

struct TokenData {
    address owner;
    string description;
    string imageUrl;
}

// Mock ERC721 contract for testing purposes
// https://wizard.openzeppelin.com
contract MockERC721 is ERC721, ERC721Enumerable {
    uint8 public basePoints;
    uint256 private _nextTokenId;
    string private _defaultImageUrl;
    NFTFactory public nftFactory;

    mapping(uint256 => TokenData) private _tokenData;

    mapping(address => uint256) public userOwnedToken;

    constructor(string memory name, string memory symbol, uint8 _basePoints, NFTFactory _nftFactory)
        ERC721(name, symbol)
    {
        nftFactory = _nftFactory;
        basePoints = _basePoints;
    }

    function getOwnedToken(address _owner) public view returns (uint256) {
        return userOwnedToken[_owner];
    }

    function safeMint(address to, string memory description) public {
        // check if the recipient already has a token
        require(balanceOf(to) == 0, "Recipient already has a token");

        uint256 tokenId = _nextTokenId++;
        TokenData memory tokenData = _tokenData[tokenId];
        tokenData.owner = to;
        tokenData.description = description;

        if (bytes(tokenData.imageUrl).length == 0) {
            tokenData.imageUrl = _defaultImageUrl;
        }
        _safeMint(to, tokenId);
    }

    function updatePoints(uint8 newPoints) public {
        basePoints = newPoints;
    }

    function getTokenData(uint256 tokenId) public view returns (TokenData memory tokenData) {
        tokenData = _tokenData[tokenId];
        return tokenData;
    }

    function getPoints() public view returns (uint8) {
        return basePoints;
    }

    function tokenURI(uint256 tokenId) public view override(ERC721) returns (string memory) {
        TokenData memory tokenData = _tokenData[tokenId];

        bytes memory attributes = abi.encodePacked(
            '{"trait_type": "ID", "value": "',
            tokenId,
            '"},',
            '{"trait_type": "name", "value": "',
            name(),
            '"}',
            '{"trait_type": "name", "value": "',
            tokenData.description,
            '"}',
            '{"trait_type": "points", "value": "',
            basePoints,
            '"}'
        );
        string memory imageUrl = bytes(tokenData.imageUrl).length > 0 ? tokenData.imageUrl : _defaultImageUrl;

        bytes memory metadata = abi.encodePacked(
            '{"name": "',
            name(),
            '", "description": "',
            tokenData.description,
            '", "image": "',
            imageUrl,
            '", "attributes": [',
            attributes,
            "]}"
        );
        return string(abi.encodePacked("data:application/json;base64,", Base64.encode(metadata)));
    }

    // The following functions are overrides required by Solidity.

    function _update(address to, uint256 tokenId, address auth)
        internal
        override(ERC721, ERC721Enumerable)
        returns (address)
    {
        return super._update(to, tokenId, auth);
    }

    function _increaseBalance(address account, uint128 value) internal override(ERC721, ERC721Enumerable) {
        super._increaseBalance(account, value);
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC721Enumerable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}
