// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import {SchemaResolver} from "eas-contracts/resolver/SchemaResolver.sol";
import {IEAS, Attestation} from "eas-contracts/IEAS.sol";
import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";

error CallerNotAttester(address caller);

/// @title AttesterResolver
/// @notice A sample schema resolver that checks whether the attestation is from a specific attester.
contract AttesterResolver is SchemaResolver, AccessControl {
    address private immutable owner;

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    event AttesterAdded(address indexed NewAttester);

    constructor(IEAS eas, address initialAttester) SchemaResolver(eas) {
        owner = initialAttester;
        _grantRole(MINTER_ROLE, initialAttester);
    }

    modifier onlyAttesters(address attester) {
        if (!hasRole(MINTER_ROLE, attester)) {
            revert CallerNotAttester(attester);
        }
        _;
    }

    function addAttester(address newAttester) external onlyAttesters(msg.sender) {
        _grantRole(MINTER_ROLE, newAttester);
        emit AttesterAdded(newAttester);
    }

    function onAttest(Attestation calldata attestation, uint256 /*value*/ ) internal view override returns (bool) {
        if (!hasRole(MINTER_ROLE, attestation.attester)) {
            revert CallerNotAttester(attestation.attester);
        } else {
            return hasRole(MINTER_ROLE, attestation.attester);
        }
    }

    function onRevoke(Attestation calldata, /*attestation*/ uint256 /*value*/ ) internal pure override returns (bool) {
        return true;
    }
}
