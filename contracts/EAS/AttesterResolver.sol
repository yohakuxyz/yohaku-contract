// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import { SchemaResolver } from "eas-contracts/resolver/SchemaResolver.sol";
import { IEAS, Attestation } from "eas-contracts/IEAS.sol";
import { AccessControl } from "@openzeppelin/contracts/access/AccessControl.sol";

/// @title AttesterResolver
/// @notice A sample schema resolver that checks whether the attestation is from a specific attester.
contract AttesterResolver is SchemaResolver, AccessControl {
    address public factory;

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    error INVALID_ATTESTER(address caller);
    error INVALID_FACTORY(address caller);

    event AttesterAdded(address indexed newAttester);

    constructor(IEAS eas, address _factory, address initialAttester) SchemaResolver(eas) {
        factory = _factory;

        _grantRole(DEFAULT_ADMIN_ROLE, _factory);
        _grantRole(MINTER_ROLE, _factory);
        _grantRole(MINTER_ROLE, initialAttester);
    }

    modifier onlyAttesters(address attester) {
        if (!hasRole(MINTER_ROLE, attester)) {
            revert INVALID_ATTESTER(attester);
        }
        _;
    }

    function addAttester(address newAttester) external onlyAttesters(msg.sender) {
        _grantRole(MINTER_ROLE, newAttester);
        emit AttesterAdded(newAttester);
    }

    function onAttest(Attestation calldata attestation, uint256 /*value*/ ) internal view override returns (bool) {
        if (!hasRole(MINTER_ROLE, attestation.attester)) {
            revert INVALID_ATTESTER(attestation.attester);
        } else {
            return hasRole(MINTER_ROLE, attestation.attester);
        }
    }

    function onRevoke(
        Attestation calldata,
        /*attestation*/
        uint256 /*value*/
    )
        internal
        pure
        override
        returns (bool)
    {
        return true;
    }
}
