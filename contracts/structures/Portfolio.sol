// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "./PortfolioEntry.sol";

struct Portfolio {
    uint256 unspemd;
    PortfolioEntry[] entries;
}