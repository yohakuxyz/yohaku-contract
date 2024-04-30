// SPDX-License-Identifier: MIT
// Compatible with OpenZeppelin Contracts ^5.0.0
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Base64.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./NFTFactory.sol";

contract SkyBlue is ERC721, AccessControl {
    using Strings for uint256;

    uint256 private _nextTokenId;
    string private _defaultImageUrl;

    mapping(uint256 => TokenData) private _tokenData;

    mapping(uint256 => address[]) public previousOwners;

    modifier onlyMinter() {
        require(hasRole(MINTER_ROLE, msg.sender), "Caller is not a minter");
        _;
    }

    modifier onlyAdmin() {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Caller is not a admin");
        _;
    }

    constructor(address initialOwner, string memory defaultImageUrl) ERC721("SkyBlueNFT", "SKB") {
        _defaultImageUrl = defaultImageUrl;
        _grantRole(DEFAULT_ADMIN_ROLE, initialOwner);
        _grantRole(MINTER_ROLE, initialOwner);
    }

    function setDefaultImageUrl(string memory defaultImageUrl) external onlyAdmin {
        _defaultImageUrl = defaultImageUrl;
    }

    function setImageURL(uint256 tokenId, string memory imageUrl) external onlyAdmin {
        _tokenData[tokenId].imageUrl = imageUrl;
    }

    function safeMint(address to) external onlyMinter {
        if (balanceOf(to) > 0) {
            revert CannotHoldMoreThanOneToken(to);
        }
        uint256 tokenId = _nextTokenId++;
        TokenData memory tokenData = _tokenData[tokenId];

        if (bytes(tokenData.imageUrl).length == 0) {
            tokenData.imageUrl = _defaultImageUrl;
        }

        _safeMint(to, tokenId);
    }

    function mintWithMetaData(address to, string memory description, string memory imageUrl) external onlyMinter {
        if (balanceOf(to) > 0) {
            revert CannotHoldMoreThanOneToken(to);
        }
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

    function setMinter(address _minter) public onlyAdmin {
        grantRole(MINTER_ROLE, _minter);
    }

    function getOwners(uint256 tokenId) public view returns (address[] memory) {
        return previousOwners[tokenId];
    }

    // The following functions are overrides required by Solidity.

    function _update(address to, uint256 tokenId, address auth) internal override(ERC721) returns (address) {
        previousOwners[tokenId].push(to);
        _tokenData[tokenId].owner = to;
        return super._update(to, tokenId, auth);
    }

    function tokenURI(uint256 tokenId) public view override(ERC721) returns (string memory) {
        // return super.tokenURI(tokenId);
        TokenData memory tokenData = _tokenData[tokenId];

        bytes memory attributes = abi.encodePacked(
            '{"trait_type": "ID", "value": "',
            tokenId.toString(),
            '"},',
            '{"trait_type": "name", "value": "',
            "SkyBlueNFT",
            '"}'
        );

        string memory imageUrl = bytes(tokenData.imageUrl).length > 0 ? tokenData.imageUrl : _defaultImageUrl;

        bytes memory metadata = abi.encodePacked(
            '{"name": "SkyBlue 2024 #',
            tokenId.toString(),
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

    function supportsInterface(bytes4 interfaceId) public view override(ERC721, AccessControl) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}
