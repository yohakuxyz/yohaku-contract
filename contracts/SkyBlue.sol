// SPDX-License-Identifier: MIT
// Compatible with OpenZeppelin Contracts ^5.0.0
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/EIP712.sol";
import "@openzeppelin/contracts/utils/Base64.sol";
import "./NFTFactory.sol";

contract SkyBlue is ERC721, ERC721Enumerable, Ownable, EIP712 {
    uint256 private _nextTokenId;
    string private _defaultImageUrl;
    NFTFactory public nftFactory;
// TODO: manage metadata
    struct TokenData {
        address minterAddress;
        string description;
        string imageUrl;
    }
    mapping(uint256 => TokenData) private _tokenData;

    mapping(uint256 => address[]) public previousOwners;

    constructor(
        address initialOwner,
        string memory defaultImageUrl,
        NFTFactory _factory
    )
        ERC721("SkyBlueNFT", "SKB")
        Ownable(initialOwner)
        EIP712("SkyBlueNFT", "1")
    {
        _defaultImageUrl = defaultImageUrl;
        nftFactory = _factory;
    }

    function getOwners(uint256 tokenId) public view returns (address[] memory) {
        return previousOwners[tokenId];
    }

    // get the total points of all the NFTs owned by the account including the previous owners
    function getTotalPoint(uint256 tokenId) public view returns (uint256) {
        uint256 totalPoints = 0;
        for (uint256 i = 0; i < previousOwners[tokenId].length; i++) {
            totalPoints += nftFactory.getTotalPoints(
                previousOwners[tokenId][i]
            );
        }
        return totalPoints;
    }

    function setDefaultImageUrl(string memory defaultImageUrl) public {
        _defaultImageUrl = defaultImageUrl;
    }

    // The following functions are overrides required.
    function safeMint(address to) public onlyOwner {
        uint256 tokenId = _nextTokenId++;
        _safeMint(to, tokenId);
    }

    // The following functions are overrides required by Solidity.

    function _update(
        address to,
        uint256 tokenId,
        address auth
    ) internal override(ERC721, ERC721Enumerable) returns (address) {
        previousOwners[tokenId].push(to);
        return super._update(to, tokenId, auth);
    }

    function _increaseBalance(
        address account,
        uint128 value
    ) internal override(ERC721, ERC721Enumerable) {
        super._increaseBalance(account, value);
    }

    function tokenURI(
        uint256 tokenId
    ) public view override(ERC721) returns (string memory) {
        // return super.tokenURI(tokenId);
        TokenData memory tokenData = _tokenData[tokenId];

        bytes memory attributes = abi.encodePacked(
            '{"trait_type": "ID", "value": "',
            tokenId,
            '"},',
            '{"trait_type": "name", "value": "',
            "SkyBlueNFT",
            '"}'
        );

        string memory imageUrl = bytes(tokenData.imageUrl).length > 0
            ? tokenData.imageUrl
            : _defaultImageUrl;

        bytes memory metadata = abi.encodePacked(
            '{"name": "SkyBlue 2024 #',
            tokenId,
            '", "description": "',
            tokenData.description,
            '", "image": "',
            imageUrl,
            '", "attributes": [',
            attributes,
            "]}"
        );
        return string(metadata);
    }

    function supportsInterface(
        bytes4 interfaceId
    ) public view override(ERC721, ERC721Enumerable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}
