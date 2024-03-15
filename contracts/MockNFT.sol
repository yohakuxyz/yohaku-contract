// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Base64.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import {IEAS, Attestation, AttestationRequest, AttestationRequestData} from "eas-contracts/IEAS.sol";
import {ISchemaRegistry} from "eas-contracts/ISchemaRegistry.sol";
import "./NFTFactory.sol";

struct TokenData {
    address owner;
    string description;
    string imageUrl;
}

// Mock ERC721 contract for testing purposes
// https://wizard.openzeppelin.com
contract MockERC721 is ERC721 {
    using Strings for uint256;

    uint8 public basePoints;
    uint256 private _nextTokenId;
    string private _defaultImageUrl;
    string schema =
        "address TokenBoundAccount,address CurrentOwner,address TokenAddress,uint256 tokenId,uint8 Score,string Description";

    NFTFactory public nftFactory;

    IEAS public eas;

    mapping(uint256 => TokenData) private _tokenData;

    mapping(address => uint256) public userOwnedToken;

    event Minted(address indexed to, address indexed account, bytes32 indexed attestationUID);

    constructor(string memory name, string memory symbol, uint8 _basePoints, NFTFactory _nftFactory)
        ERC721(name, symbol)
    {
        nftFactory = _nftFactory;
        basePoints = _basePoints;

        eas = nftFactory.eas();
    }

    function _attest(address account, address owner, uint256 tokenId, uint8 score, string memory description)
        internal
        returns (bytes32 attestationUID)
    {
        // "address TokenBoundAccount,address CurrentOwner,address TokenAddress,uint256 tokenId,uint8 Score,string Description";
        bytes memory data = abi.encode(account, owner, address(this), tokenId, score, description);
        AttestationRequestData memory requestData = AttestationRequestData({
            recipient: owner,
            expirationTime: 0,
            revocable: true,
            refUID: 0x0,
            data: data,
            value: 0
        });
        AttestationRequest memory request = AttestationRequest({schema: nftFactory.schemaUID(), data: requestData});
        attestationUID = eas.attest(request);
    }

    function getOwnedToken(address _owner) public view returns (uint256) {
        return userOwnedToken[_owner];
    }

    // TODO: access control
    function safeMint(address to, address account, string memory description) external returns (bytes32) {
        // check if the recipient already has a token
        require(balanceOf(to) == 0, "Recipient already has a token");

        uint256 tokenId = _nextTokenId++;
        TokenData memory tokenData = _tokenData[tokenId];
        tokenData.owner = to;
        tokenData.description = description;

        if (bytes(tokenData.imageUrl).length == 0) {
            tokenData.imageUrl = _defaultImageUrl;
        }

        bytes32 uid = _attest(account, to, tokenId, basePoints, description);

        require(uid != 0x0, "Attestation failed");

        _safeMint(to, tokenId);

        emit Minted(to, account, uid);

        return uid;
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
            tokenId.toString(),
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

    function _update(address to, uint256 tokenId, address auth) internal override(ERC721) returns (address) {
        return super._update(to, tokenId, auth);
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC721) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}
