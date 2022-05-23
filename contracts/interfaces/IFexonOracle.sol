// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

interface IFexonOracle {
    function getCurrentPrice(address coin) external view returns (int256);

    function getAveragePrice(address coin, uint256 daySample)
        external
        view
        returns (int256);
}
