// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "../structures/Portfolio.sol";
import "../interfaces/IFexonTradeAlgoritm.sol";

contract FexonBallsDeepTradeAlgorithm is IFexonTradeAlgorithm {
    constructor() {}

    function getRatios(Portfolio calldata portfolio) override public pure returns(TradeData[] memory) {
        require(portfolio.entries.length > 1, "Need at least two coins to calculate ratios.");
        TradeData[] memory tradeData = new TradeData[](portfolio.entries.length);
        tradeData[0] = TradeData(
                portfolio.entries[0].coin,
                (portfolio.unspemd * 90) / 100
            );
        uint256 leftover = portfolio.unspemd - ((portfolio.unspemd * 90) / 100);
        for(uint256 i = 1; i < portfolio.entries.length; i++) {
            tradeData[i] = TradeData(
                portfolio.entries[i].coin,
                leftover / (portfolio.entries.length - 1)
            );
        }
        return tradeData;   
    }
}