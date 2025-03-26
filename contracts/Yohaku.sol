// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import { ERC721Upgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import { AccessControlUpgradeable } from "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import { ERC721PausableUpgradeable } from
    "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721PausableUpgradeable.sol";
import { Initializable } from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/utils/Base64.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

import { ISemver } from "./interfaces/ISemver.sol";

/// @title Core ERC721 Upgradeable smart contract for Yohaku NFT
/// @author shutanaka.eth
/// @dev Transparent upgradeable ERC721 contract with pausable and access control from OpenZeppelin
contract Yohaku is Initializable, ERC721Upgradeable, ERC721PausableUpgradeable, AccessControlUpgradeable, ISemver {
    using Strings for uint256;

    string public defaultImageUrl;
    string public defaultDescription;
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    uint256 private _nextTokenId;

    /// @notice mapping of token ID to TokenData struct
    mapping(uint256 => TokenData) public tokenData;

    /// @notice mapping of token ID to previous owners
    mapping(uint256 => address[]) public previousOwners;

    error ALREADY_HAVE_TOKEN(address owner);

    struct TokenData {
        address owner;
        string description;
        string imageUrl;
    }

    function version() public pure virtual returns (string memory) {
        return "1.0.0";
    }

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(
        address initialOwner,
        string memory description,
        string memory imageURL
    )
        public
        virtual
        initializer
    {
        __ERC721_init("YohakuNFT", "YHK");
        __ERC721Pausable_init();
        __AccessControl_init();

        _grantRole(DEFAULT_ADMIN_ROLE, initialOwner);
        _grantRole(MINTER_ROLE, initialOwner);
        _grantRole(PAUSER_ROLE, initialOwner);

        defaultDescription = description;
        defaultImageUrl = imageURL;
    }

    /// @notice Set the default image URL to be used when tokenURI() is called
    /// @dev The caller must have the DEFAULT_ADMIN_ROLE
    /// @param imageURL The default image URL to be used when tokenURI() is called
    function setDefaultImageUrl(string memory imageURL) external onlyRole(DEFAULT_ADMIN_ROLE) {
        defaultImageUrl = imageURL;
    }

    /// @notice Set an Image URL for the given token ID
    /// @dev The caller must have the DEFAULT_ADMIN_ROLE
    /// @param tokenId The token ID
    /// @param imageUrl The URL of the image to be displayed
    function setImageURL(uint256 tokenId, string memory imageUrl) external onlyRole(DEFAULT_ADMIN_ROLE) {
        tokenData[tokenId].imageUrl = imageUrl;
    }

    /// @notice Mint a new NFT to the given address
    /// @dev The caller must have the MINTER_ROLE.
    /// If 'imageUrl' is empty, the default image URL will be used when tokenURI() is called, and store empty string in
    /// the tokenData mapping.
    /// We don't store the default image URL in the tokenData mapping to avoid conflicts when owner updated default
    /// image URL.
    /// e.g. If we store the default image URL in the tokenData mapping here and then update the default image URL, the
    /// tokenURI() will return the old default image URL.
    /// @dev Each address can hold only one Token, if the address already holds a token, it will be reverted.
    /// @param recipient The address to mint the NFT to
    /// @param imageUrl The URL of the image to be displayed
    /// @return The TokenData struct of the minted token
    function safeMint(
        address recipient,
        string memory imageUrl
    )
        external
        onlyRole(MINTER_ROLE)
        returns (TokenData memory)
    {
        // revert if the address already holds a token
        if (balanceOf(recipient) > 0) {
            revert ALREADY_HAVE_TOKEN(recipient);
        }

        // increment the next token ID
        uint256 tokenId = _nextTokenId++;

        // create a new TokenData struct and store it in the mapping
        TokenData memory newTokenData =
            TokenData({ owner: recipient, description: defaultDescription, imageUrl: imageUrl });
        tokenData[tokenId] = newTokenData;

        // mint the token
        _safeMint(recipient, tokenId);

        // return the TokenData struct
        return newTokenData;
    }

    function setMinter(address minter) public onlyRole(DEFAULT_ADMIN_ROLE) {
        grantRole(MINTER_ROLE, minter);
    }

    /// @notice Get the previous owners of the given token ID
    /// @param tokenId The token ID
    /// @return An array of addresses representing the previous owners
    function getOwners(uint256 tokenId) public view returns (address[] memory) {
        return previousOwners[tokenId];
    }

    /// @notice Get the TokenData struct of the given token ID
    /// @param tokenId The token ID
    /// @return The TokenData struct of the given token ID
    function getTokenData(uint256 tokenId) public view returns (TokenData memory) {
        return tokenData[tokenId];
    }

    function pause() public onlyRole(PAUSER_ROLE) {
        _pause();
    }

    function unpause() public onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    // The following functions are overrides required by Solidity.

    /// @notice Updates the owner of the given token ID
    /// @dev This function is called by transfer() and safeTransferFrom() to update the owner of the token.
    /// @dev It also stores the previous owner in the previousOwners mapping.
    function _update(
        address to,
        uint256 tokenId,
        address auth
    )
        internal
        override(ERC721Upgradeable, ERC721PausableUpgradeable)
        returns (address)
    {
        previousOwners[tokenId].push(to);
        tokenData[tokenId].owner = to;
        return super._update(to, tokenId, auth);
    }

    /// @notice Returns the token URI for the given token ID
    /// @dev The token URI is generated using the token ID and the tokenData mapping.
    /// @dev attributes and metadata is optimized for OpenSea
    /// @param tokenId The token ID
    /// @return The token URI
    function tokenURI(uint256 tokenId) public view override(ERC721Upgradeable) returns (string memory) {
        TokenData memory data = tokenData[tokenId];

        bytes memory attributes = abi.encodePacked(
            '{"trait_type": "ID", "value": "',
            tokenId.toString(),
            '"},',
            '{"trait_type": "name", "value": "',
            "[]Yohaku",
            '"}'
        );

        string memory imageUrl = bytes(data.imageUrl).length > 0 ? data.imageUrl : defaultImageUrl;

        bytes memory metadata = abi.encodePacked(
            '{"name": "[]Yohaku #',
            tokenId.toString(),
            '", "description": "',
            data.description,
            '", "image": "',
            imageUrl,
            '", "attributes": [',
            attributes,
            "]}"
        );
        return string(abi.encodePacked("data:application/json;base64,", Base64.encode(metadata)));
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721Upgradeable, AccessControlUpgradeable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
