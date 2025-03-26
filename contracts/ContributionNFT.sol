// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import { ERC721 } from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import { AccessControl } from "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Base64.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

import { IEAS, Attestation, AttestationRequest, AttestationRequestData } from "eas-contracts/IEAS.sol";
import { ISchemaRegistry } from "eas-contracts/ISchemaRegistry.sol";

import { NFTFactory } from "./NFTFactory.sol";

/// @title Contribution NFT smart contract
/// @author shutanaka.eth
/// @notice ERC721 smart contract which represents each contribution as an NFT
/// @dev ERC721 smart contract with AccessControl from OpenZeppelin
/// @dev Ensure that Contribution NFTs are minted by the NFTFactory contract
contract ContributionNFT is ERC721, AccessControl {
    using Strings for uint256;

    uint8 public basePoints;
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    uint256 private _nextTokenId;
    string public defaultImageUrl;
    string schema =
        "address TokenBoundAccount,address CurrentOwner,address TokenAddress,uint256 tokenId,uint8 Score,string Description";
    NFTFactory public nftFactory;
    IEAS public eas;

    mapping(uint256 => TokenData) private _tokenData;

    error ALREADY_HAVE_TOKEN(address owner);
    error INVALID_MINTER(address minter);
    error INVALID_ADMIN(address admin);

    struct TokenData {
        address owner;
        string description;
        string imageUrl;
    }

    event Minted(address indexed to, address indexed account, bytes32 indexed attestationUID);
    event PointUpdated(uint8 point);

    constructor(
        string memory name,
        string memory symbol,
        uint8 _basePoints,
        NFTFactory _nftFactory,
        string memory _defaultImageUrl,
        address initialMinter
    )
        ERC721(name, symbol)
    {
        nftFactory = _nftFactory;
        basePoints = _basePoints;
        defaultImageUrl = _defaultImageUrl;

        _grantRole(DEFAULT_ADMIN_ROLE, initialMinter);
        _grantRole(MINTER_ROLE, initialMinter);

        eas = nftFactory.eas();
    }

    function setDefaultImageUrl(string memory imageURL) external onlyRole(DEFAULT_ADMIN_ROLE) {
        defaultImageUrl = imageURL;
    }

    function setImageURL(uint256 tokenId, string memory imageUrl) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _tokenData[tokenId].imageUrl = imageUrl;
    }

    /// @dev create a new attestation
    /// @param to current owner of the token bound account and recipient of the NFT
    /// @param account The Token Bound Account that receives the attestation
    /// @param tokenId The id of the Yohaku NFT
    /// @param score The score
    /// @param description The description of the NFT
    /// @return attestationUID The unique identifier of the attestation
    function _attest(
        address to,
        address account,
        uint256 tokenId,
        uint8 score,
        string memory description
    )
        internal
        returns (bytes32 attestationUID)
    {
        // "address TokenBoundAccount,address CurrentOwner,address TokenAddress,uint256 tokenId,uint8 Score,string
        // Description";
        bytes memory data = abi.encode(account, to, address(this), tokenId, score, description);
        AttestationRequestData memory requestData = AttestationRequestData({
            recipient: account,
            expirationTime: 0,
            revocable: true,
            refUID: 0x0,
            data: data,
            value: 0
        });
        AttestationRequest memory request = AttestationRequest({ schema: nftFactory.schemaUID(), data: requestData });
        attestationUID = eas.attest(request);
    }

    /// @notice Mint a new NFT and send it to the recipient
    /// @param to The recipient of the NFT
    /// @param account The Token Bound Account that receives the attestation
    /// @param description The description of the NFT
    /// @param imageUrl The URL of the image to be displayed
    function safeMint(
        address to,
        address account,
        string memory description,
        string memory imageUrl
    )
        external
        onlyRole(MINTER_ROLE)
        returns (bytes32)
    {
        uint256 tokenId = _nextTokenId++;

        bytes32 uid = _beforeMint(tokenId, to, account, description, imageUrl);

        // send nft to the current owner of token bound account
        _safeMint(to, tokenId);

        // emit Minted event
        emit Minted(to, account, uid);

        return uid;
    }

    function _beforeMint(
        uint256 tokenId,
        address to,
        address account,
        string memory description,
        string memory imageUrl
    )
        internal
        returns (bytes32 uid)
    {
        if (balanceOf(to) > 0) {
            revert ALREADY_HAVE_TOKEN(to);
        }
        // store token data
        TokenData memory tokenData = _tokenData[tokenId];
        tokenData.owner = to;
        tokenData.description = description;
        tokenData.imageUrl = imageUrl;

        // create new attestation
        // the recipient of attestation must be the token bound accout
        uid = _attest(to, account, tokenId, basePoints, description);

        require(uid != 0x0, "Attestation failed");

        return uid;
    }

    function batchMint(
        address[] memory to,
        address[] memory account,
        string memory description,
        string memory imageUrl
    )
        external
        onlyRole(MINTER_ROLE)
    {
        require(to.length == account.length, "to and account length must be equal");
        for (uint256 i = 0; i < to.length; i++) {
            uint256 tokenId = _nextTokenId++;

            bytes32 uid = _beforeMint(tokenId, to[i], account[i], description, imageUrl);

            _safeMint(to[i], tokenId);

            // emit Minted event
            emit Minted(to[i], account[i], uid);
        }
    }

    function updatePoints(uint8 newPoints) external onlyRole(DEFAULT_ADMIN_ROLE) {
        basePoints = newPoints;
        emit PointUpdated(newPoints);
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
            '{"trait_type": "description", "value": "',
            tokenData.description,
            '"}',
            '{"trait_type": "points", "value": "',
            basePoints,
            '"}'
        );
        string memory imageUrl = bytes(tokenData.imageUrl).length > 0 ? tokenData.imageUrl : defaultImageUrl;

        bytes memory metadata = abi.encodePacked(
            '{"name": "',
            name(),
            " #",
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

    // The following functions are overrides required by Solidity.

    function _update(address to, uint256 tokenId, address auth) internal override(ERC721) returns (address) {
        return super._update(to, tokenId, auth);
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC721, AccessControl) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}
