// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "../structures/TradeData.sol";
import "../structures/Portfolio.sol";

interface IFexonTradeAlgorithm {
    function getRatios(Portfolio calldata portfolio)
        external
        returns (TradeData[] memory);
}
