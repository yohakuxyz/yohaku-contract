// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import {SchemaResolver} from "eas-contracts/resolver/SchemaResolver.sol";

import {IEAS, Attestation} from "eas-contracts/IEAS.sol";

/// @title AttesterResolver
/// @notice A sample schema resolver that checks whether the attestation is from a specific attester.
contract AttesterResolver is SchemaResolver {
    address private immutable _targetAttester;
    address[] public attesters;

    error CallerNotAttester(address caller);

    constructor(IEAS eas, address initialAttester) SchemaResolver(eas) {
        _targetAttester = initialAttester;
        attesters.push(initialAttester);
    }

    modifier onlyAttesters() {
        if (!_isAttester(msg.sender)) {
            revert CallerNotAttester(msg.sender);
        }
        _;
    }

    // TODO: onlyAttesters
    function addAttester(address newAttester) external /*onlyAttesters*/ {
        attesters.push(newAttester);
    }

    function _isAttester(address attester) internal view returns (bool) {
        for (uint256 i = 0; i < attesters.length; i++) {
            if (attesters[i] == attester) {
                return true;
            }
        }
        return false;
    }

    function onAttest(Attestation calldata attestation, uint256 /*value*/ ) internal view override returns (bool) {
        return _isAttester(attestation.attester);
    }

    function onRevoke(Attestation calldata, /*attestation*/ uint256 /*value*/ ) internal pure override returns (bool) {
        return true;
    }
}
