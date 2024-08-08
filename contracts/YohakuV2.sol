// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Yohaku} from "./Yohaku.sol";

/// @custom:oz-upgrades-from Yohaku
contract YohakuV2 is Yohaku {
    function revokeMinter(address minter) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _revokeRole(MINTER_ROLE, minter);
    }
}
