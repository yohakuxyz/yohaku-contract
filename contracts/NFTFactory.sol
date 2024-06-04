// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import {IEAS, Attestation} from "eas-contracts/IEAS.sol";
import {ISchemaRegistry} from "eas-contracts/ISchemaRegistry.sol";
import {SchemaResolver} from "eas-contracts/resolver/SchemaResolver.sol";
import {ISchemaResolver} from "eas-contracts/resolver/ISchemaResolver.sol";
import "./EAS/AttesterResolver.sol";
import "./ContributionNFT.sol";

contract NFTFactory {
    bytes32 public schemaUID;
    ContributionNFT[] public erc721s;
    IEAS public eas;
    AttesterResolver public resolver;

    event FactoryCreated(address factoryAddress, address easAddress, address resolverAddress, bytes32 schemaUID);

    event NFTCreated(address nftAddress);

    constructor(address initialMinter, IEAS _eas, ISchemaRegistry _schemaRegistry) {
        // set EAS contract
        eas = _eas;

        // deploy AttesterResolver contract
        resolver = new AttesterResolver(eas, address(this));
        // add initialMinter as attester
        resolver.addAttester(initialMinter);

        // register new schema
        bytes32 _schemaUID = _schemaRegistry.register(
            "address TokenBoundAccount,address CurrentOwner,address TokenAddress,uint256 tokenId,uint8 Score,string Description",
            ISchemaResolver(address(resolver)),
            true
        );

        // set schemaUID
        schemaUID = _schemaUID;

        // emit FactoryCreated event
        emit FactoryCreated(address(this), address(eas), address(resolver), schemaUID);
    }

    // owner => tokenAddress => tokenIds
    mapping(address => mapping(address => uint256[])) private _ownedTokens;

    function createERC721(
        string calldata name,
        string calldata symbol,
        uint8 _basePoints,
        string memory _defaultImageUrl,
        address initialMinter
    ) public returns (ContributionNFT) {
        ContributionNFT nft =
            new ContributionNFT(name, symbol, _basePoints, NFTFactory(address(this)), _defaultImageUrl, initialMinter);
        erc721s.push(nft);
        resolver.addAttester(address(nft));
        emit NFTCreated(address(nft));
        return nft;
    }

    function getCreatedERC721s() public view returns (ContributionNFT[] memory) {
        return erc721s;
    }
}
