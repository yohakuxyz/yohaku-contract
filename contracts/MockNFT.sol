// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Base64.sol";

// Mock ERC721 contract for testing purposes
// https://wizard.openzeppelin.com
contract MockERC721 is ERC721 {
    uint256 private _nextTokenId;
    string private _defaultImageUrl;

    uint256 public points;

    struct TokenData {
        address owner;
        string description;
        string imageUrl;
    }
    mapping(uint256 => TokenData) private _tokenData;

    constructor(
        uint256 points_,
        string memory name,
        string memory symbol
    ) ERC721(name, symbol) {
        points = points_;
    }

    function safeMint(address to, string memory description) public {
        uint256 tokenId = _nextTokenId++;
        TokenData memory tokenData = _tokenData[tokenId];
        tokenData.owner = to;
        tokenData.description = description;

        if (bytes(tokenData.imageUrl).length == 0) {
            tokenData.imageUrl = _defaultImageUrl;
        }
        _safeMint(to, tokenId);
    }

    function getPoints() public view returns (uint256) {
        return points;
    }

    function tokenURI(
        uint256 tokenId
    ) public view override(ERC721) returns (string memory) {
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
            points,
            '"}'
        );
        string memory imageUrl = bytes(tokenData.imageUrl).length > 0
            ? tokenData.imageUrl
            : _defaultImageUrl;

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
        return
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    Base64.encode(metadata)
                )
            );
    }
}

contract MockERC1155 is ERC1155, ERC1155Supply {
    // Ideally, this should be a mapping from token ID to points
    uint256 public points;

    constructor(uint256 points_) ERC1155("") {
        points = points_;
    }

    function mint(
        address account,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public {
        _mint(account, id, amount, data);
    }

    function mintBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public {
        _mintBatch(to, ids, amounts, data);
    }

    function getPoints() public view returns (uint256) {
        return points;
    }

    // The following functions are overrides required by Solidity.

    function _update(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory values
    ) internal override(ERC1155, ERC1155Supply) {
        super._update(from, to, ids, values);
    }
}
