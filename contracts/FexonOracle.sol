// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "./structures/PriceProvider.sol";

import "../dependencies/openzeppelin-contracts/contracts/access/Ownable.sol";
import "../dependencies/chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "../dependencies/chainlink/contracts/src/v0.8/interfaces/KeeperCompatibleInterface.sol";

contract FexonOracle is Ownable {
    uint256 private constant PHASE_OFFSET = 64;
    uint256 private constant SECONDS_IN_A_DAY = 86400;

    mapping(address => AggregatorV3Interface) private _sources;

    constructor() {}

    function getCurrentPrice(address coin) public view returns (int256) {
        AggregatorV3Interface feed = _sources[coin];
        (, int256 price, , , ) = feed.latestRoundData();
        return price;
    }

    function getAveragePrice(address coin, uint256 daySample)
        public
        view
        returns (int256)
    {
        uint256 targetTimestamp = block.timestamp -
            (daySample * SECONDS_IN_A_DAY);
        AggregatorV3Interface feed = _sources[coin];
        
        (uint80 roundId, int256 price, , uint256 timestamp, ) = feed
            .latestRoundData();

        int256 cumulativePrice = price;
        int256 samples = 1;

        while (timestamp > targetTimestamp) {
            uint80 previoudRoundId = _getPreviousRoundId(roundId);
            (roundId, price, , timestamp, ) = feed.getRoundData(
                previoudRoundId
            );
            cumulativePrice += price;
            samples += 1;
        }

        return cumulativePrice / samples;
    }

    function addAggregator(PriceProvider calldata provider) public onlyOwner {
        _addAggregator(provider);
    }

    function _addAggregator(PriceProvider calldata provider) private {
        _sources[provider.coin] = AggregatorV3Interface(provider.aggregator);
    }

    function _getPreviousRoundId(uint256 roundId)
        private
        pure
        returns (uint80)
    {
        uint16 phaseId = uint16(roundId >> PHASE_OFFSET);
        uint64 aggregatorRoundId = uint64(roundId) - 1;

        return uint80((uint256(phaseId) << PHASE_OFFSET) | aggregatorRoundId);
    }
}
