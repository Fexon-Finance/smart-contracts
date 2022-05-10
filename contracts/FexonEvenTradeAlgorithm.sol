// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "./structures/Portfolio.sol";
import "./interfaces/IFexonTradeAlgoritm.sol";

contract FexonEvenTradeAlgorithm is IFexonTradeAlgorithm {
    constructor() {}

    function getRatios(Portfolio calldata portfolio) override public pure returns(TradeData[] memory) {
        TradeData[] memory tradeData = new TradeData[](portfolio.entries.length);
        for(uint256 i = 0; i < portfolio.entries.length; i++) {
            tradeData[i] = TradeData(
                portfolio.entries[i].coin,
                portfolio.unspemd / portfolio.entries.length
            );
        }
        return tradeData;
    }
}