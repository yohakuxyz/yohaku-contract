// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

// Mock ERC721 contract for testing purposes
// https://wizard.openzeppelin.com
contract MockERC721 is ERC721 {
    uint256 private _nextTokenId;

    uint8 public _points;

    constructor(uint8 points_) ERC721("Mock", "MOCK") {
        _points = points_;
    }

    function safeMint(address to) public {
        uint256 tokenId = _nextTokenId++;
        _safeMint(to, tokenId);
    }

    function getPoinst() public view returns (uint8) {
        return _points;
    }
}

contract MockERC1155 is ERC1155, ERC1155Supply {
    // Ideally, this should be a mapping from token ID to points
    uint8 public _points;

    constructor(uint8 points_) ERC1155("") {
        _points = points_;
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

    function getPoinst() public view returns (uint8) {
        return _points;
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
