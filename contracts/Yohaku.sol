// SPDX-License-Identifier: MIT
// Compatible with OpenZeppelin Contracts ^5.0.0
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Base64.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

error CannnotHoldMoreThanOneYohakuNFT(address owner);

contract Yohaku is ERC721, AccessControl {
    using Strings for uint256;

    uint256 private _nextTokenId;
    string private _defaultImageUrl;

    string public description;

    struct TokenData {
        address owner;
        string description;
        string imageUrl;
    }

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    mapping(uint256 => TokenData) public _tokenData;

    mapping(uint256 => address[]) public previousOwners;

    modifier onlyMinter() {
        require(hasRole(MINTER_ROLE, msg.sender), "Caller is not a minter");
        _;
    }

    modifier onlyAdmin() {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Caller is not a admin");
        _;
    }

    constructor(address initialOwner, string memory _description, string memory defaultImageUrl)
        ERC721("YohakuNFT", "YHK")
    {
        _defaultImageUrl = defaultImageUrl;
        description = _description;
        _grantRole(DEFAULT_ADMIN_ROLE, initialOwner);
        _grantRole(MINTER_ROLE, initialOwner);
    }

    function setDefaultImageUrl(string memory defaultImageUrl) external onlyAdmin {
        _defaultImageUrl = defaultImageUrl;
    }

    function setImageURL(uint256 tokenId, string memory imageUrl) external onlyAdmin {
        _tokenData[tokenId].imageUrl = imageUrl;
    }

    function safeMint(address to, string memory imageUrl) external onlyMinter returns (TokenData memory) {
        if (balanceOf(to) > 0) {
            revert CannnotHoldMoreThanOneYohakuNFT(to);
        }
        uint256 tokenId = _nextTokenId++;

        TokenData memory newTokenData = TokenData({
            owner: to,
            description: description,
            imageUrl: bytes(imageUrl).length > 0 ? imageUrl : _defaultImageUrl
        });

        _tokenData[tokenId] = newTokenData;

        _safeMint(to, tokenId);

        return newTokenData;
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
            "YohakuNFT",
            '"}'
        );

        string memory imageUrl = bytes(tokenData.imageUrl).length > 0 ? tokenData.imageUrl : _defaultImageUrl;

        bytes memory metadata = abi.encodePacked(
            '{"name": "Yohaku 2024 #',
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
