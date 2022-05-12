// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "https://github.com/pancakeswap/pancake-smart-contracts/blob/master/projects/exchange-protocol/contracts/interfaces/IPancakeRouter02.sol";
import "https://github.com/pancakeswap/pancake-smart-contracts/blob/master/projects/exchange-protocol/contracts/interfaces/IPancakeFactory.sol";
import "https://github.com/pancakeswap/pancake-smart-contracts/blob/master/projects/exchange-protocol/contracts/interfaces/IPancakePair.sol";
import "./interfaces/IFexonTradeAlgoritm.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract FexonCore is ERC20, Ownable {
    IPancakeRouter02 private _pancakeRouter;
    IFexonTradeAlgorithm private _fexonTradeAlgorithm;
    address[] _coins;
    address private _WBNB = 0xae13d989daC2f0dEbFf460aC112a837C89BAa7cd;

    constructor(
        address pancakeRouter,
        address fexonTradeAlgorithm,
        address[] memory coins,
        string memory tokenName,
        string memory tokenSymbol
    ) 
    ERC20(tokenName, tokenSymbol) {
        _pancakeRouter = IPancakeRouter02(pancakeRouter);
        _fexonTradeAlgorithm = IFexonTradeAlgorithm(fexonTradeAlgorithm);
        _coins = coins;
    }

    function buy() public payable {
        Portfolio memory portfolio = _buildPortfolio();
        TradeData[] memory tradeData = _fexonTradeAlgorithm.getRatios(portfolio);

        for(uint i = 0; i < tradeData.length ; i++) {
            _buyCoin(tradeData[i]);
        }

        _mint(msg.sender, msg.value);
    }

    function sell(uint256 amount) public {
        uint256 b = balanceOf(msg.sender);
        require(amount <= b, "Insufficient balance");
        uint256 ratio = ((b * 100) / totalSupply()) / _coins.length;

        for(uint i = 0; i < _coins.length ; i++) {
            uint256 _amount = (IERC20(_coins[i]).balanceOf(address(this)) * ratio) / 100;
            _sellCoin(_amount, _coins[i]);
        }

        _burn(msg.sender, amount);
    }

    function viewPortfolio() public view returns (PortfolioEntry[] memory) {
        PortfolioEntry[] memory portfolio = new PortfolioEntry[](_coins.length);
        for(uint i = 0; i < _coins.length ; i++) {
            IERC20 coin = IERC20(_coins[i]);
            portfolio[i] = PortfolioEntry(
                address(coin),
                coin.balanceOf(address(this))
            );
        }
        return portfolio;
    }

    function changeAlgorithm(address algorithmAddress) public onlyOwner {
        _fexonTradeAlgorithm = IFexonTradeAlgorithm(algorithmAddress);
    }

    function _buyCoin(TradeData memory data) private {
        address[] memory pool = new address[](2);
        pool[0] = _WBNB;
        pool[1] = data.coin; 

        _pancakeRouter
            .swapExactETHForTokens{value: data.amount} (
                0,
                pool,
                address(this),
                block.timestamp
            );
    }

    function _sellCoin(
        uint256 amount,
        address coin
    ) private {
        address[] memory pool = new address[](2);
        pool[0] = coin;
        pool[1] = _WBNB; 

        IERC20(coin).approve(address(_pancakeRouter), amount);
        _pancakeRouter
            .swapExactTokensForTokensSupportingFeeOnTransferTokens(
                amount,
                0,
                pool,
                msg.sender,
                block.timestamp
            );
    }

    function _buildPortfolio() private view returns (Portfolio memory){
        PortfolioEntry[] memory entries = new PortfolioEntry[](_coins.length);
        for(uint256 i = 0; i < _coins.length; i++) {
            IERC20 coin = IERC20(_coins[i]);
            entries[i] = PortfolioEntry(
                address(coin), 
                coin.balanceOf(address(this))
            );
        }
        Portfolio memory portfolio = Portfolio(
            address(this).balance,
            entries
        );
        return portfolio;
    }
}