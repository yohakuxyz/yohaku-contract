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

// TODO: should manage permission
contract SkyBlue is ERC721, ERC721Enumerable, Ownable {
    uint256 private _nextTokenId;
    string private _defaultImageUrl;
    NFTFactory public nftFactory;

    mapping(uint256 => TokenData) private _tokenData;

    mapping(uint256 => address[]) public previousOwners;

    constructor(address initialOwner, string memory defaultImageUrl, NFTFactory _factory)
        ERC721("SkyBlueNFT", "SKB")
        Ownable(initialOwner)
    {
        _defaultImageUrl = defaultImageUrl;
        nftFactory = _factory;
    }

    function setDefaultImageUrl(string memory defaultImageUrl) public {
        _defaultImageUrl = defaultImageUrl;
    }

    function setImageURL(uint256 tokenId, string memory imageUrl) public onlyOwner {
        _tokenData[tokenId].imageUrl = imageUrl;
    }

    function safeMint(address to) external onlyOwner {
        uint256 tokenId = _nextTokenId++;
        TokenData memory tokenData = _tokenData[tokenId];

        if (bytes(tokenData.imageUrl).length == 0) {
            tokenData.imageUrl = _defaultImageUrl;
        }

        _safeMint(to, tokenId);
    }

    function mintWithMetaData(address to, string memory description, string memory imageUrl) external onlyOwner {
        uint256 tokenId = _nextTokenId++;
        TokenData memory tokenData = _tokenData[tokenId];
        tokenData.owner = to;
        tokenData.description = description;
        tokenData.imageUrl = imageUrl;

        if (bytes(tokenData.imageUrl).length == 0) {
            tokenData.imageUrl = _defaultImageUrl;
        }

        _safeMint(to, tokenId);
    }

    function getOwners(uint256 tokenId) public view returns (address[] memory) {
        return previousOwners[tokenId];
    }

    // get the total points of all the NFTs owned by the account including the previous owners
    function getTotalPoint(uint256 tokenId) public view returns (uint256) {
        uint256 totalPoints = 0;
        for (uint256 i = 0; i < previousOwners[tokenId].length; i++) {
            totalPoints += nftFactory.getTotalPoints(previousOwners[tokenId][i]);
        }
        return totalPoints;
    }

    // The following functions are overrides required by Solidity.

    function _update(address to, uint256 tokenId, address auth)
        internal
        override(ERC721, ERC721Enumerable)
        returns (address)
    {
        previousOwners[tokenId].push(to);
        _tokenData[tokenId].owner = to;
        return super._update(to, tokenId, auth);
    }

    function _increaseBalance(address account, uint128 value) internal override(ERC721, ERC721Enumerable) {
        super._increaseBalance(account, value);
    }

    function tokenURI(uint256 tokenId) public view override(ERC721) returns (string memory) {
        // return super.tokenURI(tokenId);
        TokenData memory tokenData = _tokenData[tokenId];

        uint256 totalPoints = getTotalPoint(tokenId);

        string[] memory contributions;

        if (previousOwners[tokenId].length > 0) {
            contributions = nftFactory.getContributions(previousOwners[tokenId]);
        }

        bytes memory attributes = abi.encodePacked(
            '{"trait_type": "ID", "value": "',
            tokenId,
            '"},',
            '{"trait_type": "name", "value": "',
            "SkyBlueNFT",
            '"}',
            '{"trait_type": "points", "value": "',
            totalPoints,
            '"}'
        );

        string memory imageUrl = bytes(tokenData.imageUrl).length > 0 ? tokenData.imageUrl : _defaultImageUrl;

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
        return string(abi.encodePacked("data:application/json;base64,", Base64.encode(metadata)));
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC721Enumerable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}
