// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import { AccessControl } from "@openzeppelin/contracts/access/AccessControl.sol";
import { IEAS, Attestation } from "eas-contracts/IEAS.sol";
import { ISchemaRegistry } from "eas-contracts/ISchemaRegistry.sol";
import { SchemaResolver } from "eas-contracts/resolver/SchemaResolver.sol";
import { ISchemaResolver } from "eas-contracts/resolver/ISchemaResolver.sol";
import "./EAS/AttesterResolver.sol";
import "./ContributionNFT.sol";

contract NFTFactory is AccessControl {
    bytes32 public schemaUID;
    ContributionNFT[] public erc721s;
    IEAS public eas;
    AttesterResolver public resolver;

    event NFTCreated(address nftAddress);
    event FactoryCreated(address factoryAddress, address easAddress, address resolverAddress, bytes32 schemaUID);

    /// @notice Initialize NFTFactory contract with EAS and EAS SchemaRegistry
    /// @dev Deploy AttesterResolver contract and register new schema
    /// Inside the AttesterResolver.sol, Grant DEFAULT_ADMIN_ROLE and MINTER_ROLE to the factory so that factory can add
    /// erc721's address as an attester when creating new erc721.
    /// Above is required because ContributionNFT contract itself attest inside the mint function.
    /// @param initialMinter The address of the initial minter
    /// @param _eas The EAS contract
    /// @param _schemaRegistry The EAS SchemaRegistry contract
    constructor(address initialMinter, IEAS _eas, ISchemaRegistry _schemaRegistry) {
        _grantRole(DEFAULT_ADMIN_ROLE, initialMinter);

        // set EAS contract
        eas = _eas;

        // deploy AttesterResolver contract
        resolver = new AttesterResolver(eas, address(this), initialMinter);

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

    function addAttester(address newAttester) external onlyRole(DEFAULT_ADMIN_ROLE) {
        resolver.addAttester(newAttester);
    }

    function createERC721(
        string calldata name,
        string calldata symbol,
        uint8 basePoints,
        string memory defaultImageUrl,
        address initialMinter
    )
        public
        returns (ContributionNFT)
    {
        ContributionNFT nft =
            new ContributionNFT(name, symbol, basePoints, NFTFactory(address(this)), defaultImageUrl, initialMinter);
        erc721s.push(nft);
        resolver.addAttester(address(nft));
        emit NFTCreated(address(nft));
        return nft;
    }

    function getCreatedERC721s() public view returns (ContributionNFT[] memory) {
        return erc721s;
    }
}
