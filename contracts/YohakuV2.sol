// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import { Yohaku } from "./Yohaku.sol";

contract YohakuV2 is Yohaku {
    function version() public pure virtual override returns (string memory) {
        return "2.0.0";
    }

    function revokeMinter(address minter) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _revokeRole(MINTER_ROLE, minter);
    }
}
