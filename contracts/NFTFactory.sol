// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import { AccessControl } from "@openzeppelin/contracts/access/AccessControl.sol";
import { Create2 } from "@openzeppelin/contracts/utils/Create2.sol";
import { IEAS, Attestation } from "eas-contracts/IEAS.sol";
import { ISchemaRegistry } from "eas-contracts/ISchemaRegistry.sol";
import { SchemaResolver } from "eas-contracts/resolver/SchemaResolver.sol";
import { ISchemaResolver } from "eas-contracts/resolver/ISchemaResolver.sol";
import "./EAS/AttesterResolver.sol";
import "./ContributionNFT.sol";

contract NFTFactory is AccessControl {
    bytes32 public schemaUID;
    address[] public erc721s;
    IEAS public eas;
    AttesterResolver public resolver;

    error ALREADY_DEPLOYED();

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
        returns (address)
    {
        require(!checkIsAddressDeployed(name, symbol, basePoints, defaultImageUrl, initialMinter), ALREADY_DEPLOYED());

        bytes32 salt =
            keccak256(abi.encodePacked(name, symbol, basePoints, address(this), defaultImageUrl, initialMinter));
        bytes memory args = abi.encode(name, symbol, basePoints, address(this), defaultImageUrl, initialMinter);

        bytes memory deployCode = abi.encodePacked(type(ContributionNFT).creationCode, args);

        address deployedAddress = Create2.deploy(0, salt, deployCode);

        erc721s.push(deployedAddress);
        resolver.addAttester(deployedAddress);
        emit NFTCreated(deployedAddress);
        return deployedAddress;
    }

    function checkIsAddressDeployed(
        string calldata name,
        string calldata symbol,
        uint8 basePoints,
        string memory defaultImageUrl,
        address initialMinter
    )
        public
        view
        returns (bool)
    {
        bytes32 salt =
            keccak256(abi.encodePacked(name, symbol, basePoints, address(this), defaultImageUrl, initialMinter));
        bytes memory args = abi.encode(name, symbol, basePoints, address(this), defaultImageUrl, initialMinter);

        bytes memory deployCode = abi.encodePacked(type(ContributionNFT).creationCode, args);

        address deployedAddress = Create2.computeAddress(salt, keccak256(deployCode));

        uint256 codeSize;
        assembly {
            codeSize := extcodesize(deployedAddress)
        }

        return codeSize > 0;
    }

    function computeERC721Address(
        string calldata name,
        string calldata symbol,
        uint8 basePoints,
        string memory defaultImageUrl,
        address initialMinter
    )
        public
        view
        returns (address)
    {
        bytes32 salt =
            keccak256(abi.encodePacked(name, symbol, basePoints, address(this), defaultImageUrl, initialMinter));
        bytes memory args = abi.encode(name, symbol, basePoints, address(this), defaultImageUrl, initialMinter);

        bytes memory deployCode = abi.encodePacked(type(ContributionNFT).creationCode, args);

        return Create2.computeAddress(salt, keccak256(deployCode));
    }

    function getCreatedERC721s() public view returns (address[] memory) {
        return erc721s;
    }
}
