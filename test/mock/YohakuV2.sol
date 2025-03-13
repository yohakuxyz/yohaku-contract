// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {Yohaku} from "../../contracts/Yohaku.sol";

/// @custom:oz-upgrades-from Yohaku
contract YohakuV2 is Yohaku {
    function initializeV2(
        address owner,
        string memory description,
        string memory imageURL
    ) public reinitializer(2) {
        defaultImageUrl = imageURL;
        defaultDescription = description;
        _grantRole(DEFAULT_ADMIN_ROLE, owner);
    }

    function version() public pure virtual override returns (string memory) {
        return "v2.0.0";
    }

    function revokeMinter(
        address minter
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _revokeRole(MINTER_ROLE, minter);
    }
}
