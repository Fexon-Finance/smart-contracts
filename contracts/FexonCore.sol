// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "./interfaces/IFexonTradeAlgoritm.sol";
import "./interfaces/IFexonOracle.sol";
import "./structures/Coin.sol";
import "./structures/TradeData.sol";

import "../dependencies/pancake-smart-contracts/projects/exchange-protocol/contracts/interfaces/IPancakeRouter02.sol";
import "../dependencies/pancake-smart-contracts/projects/exchange-protocol/contracts/interfaces/IPancakeFactory.sol";
import "../dependencies/pancake-smart-contracts/projects/exchange-protocol/contracts/interfaces/IPancakePair.sol";
import "../dependencies/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import "../dependencies/openzeppelin-contracts/contracts/access/Ownable.sol";
import "../dependencies/chainlink/contracts/src/v0.8/interfaces/KeeperCompatibleInterface.sol";

contract FexonCore is ERC20, Ownable, KeeperCompatibleInterface {
    IPancakeRouter02 private _pancakeRouter;
    IFexonTradeAlgorithm private _fexonTradeAlgorithm;
    IFexonOracle private _fexonOracle;
    Coin[] private _coins;
    address private _WBNB = 0xae13d989daC2f0dEbFf460aC112a837C89BAa7cd;
    address private _BUSD = 0xeD24FC36d5Ee211Ea25A80239Fb8C4Cfd80f12Ee;
    
    constructor(
        address pancakeRouter,
        address fexonTradeAlgorithm,
        address fexonOracle,
        Coin[] memory coins,
        string memory tokenName,
        string memory tokenSymbol
    ) ERC20(tokenName, tokenSymbol) {
        _pancakeRouter = IPancakeRouter02(pancakeRouter);
        _fexonTradeAlgorithm = IFexonTradeAlgorithm(fexonTradeAlgorithm);
        _fexonOracle = IFexonOracle(fexonOracle);
        for(uint256 i = 0; i < coins.length; i++) {
            _coins.push(Coin(coins[i].symbol, coins[i].coinAddress));    
        }
    }

    function buy() public payable {
        uint256 etf = msg.value * (10 ** 8) / getCurrentPrice();
        require(etf > 0, "Not enough BNB for ETF token");

        TradeData[] memory tradeData = _fexonTradeAlgorithm.getRatios(_buildPortfolio());
        for(uint i = 0; i < tradeData.length ; i++) {
            _buyCoin(tradeData[i]);
        }
       
        _mint(msg.sender, etf);
    }

    function sell(uint256 amount) public {
        uint256 callerBalance = balanceOf(msg.sender);
        require(amount <= callerBalance, "Insufficient balance");
        uint256 ratio = ((callerBalance * 100) / totalSupply());

        for(uint i = 0; i < _coins.length ; i++) {
            uint256 coinLimit = (IERC20(_coins[i].coinAddress).balanceOf(address(this)) * ratio) / 100;
            uint256 callerRatio = (amount * 100) / callerBalance;
            uint256 sellAmount = (coinLimit * callerRatio) / 100;
            _sellCoin(sellAmount, _coins[i].coinAddress);
        }

        _burn(msg.sender, amount);
        }

    function viewPortfolio() public view returns (PortfolioEntry[] memory) {
        PortfolioEntry[] memory portfolio = new PortfolioEntry[](_coins.length);
        for (uint256 i = 0; i < _coins.length; i++) {
            IERC20 coin = IERC20(_coins[i].coinAddress);
            portfolio[i] = PortfolioEntry(
                address(coin),
                _coins[i].symbol,
                coin.balanceOf(address(this))
            );
        }
        return portfolio;
    }

    function changeAlgorithm(address algorithmAddress) public onlyOwner {
        _fexonTradeAlgorithm = IFexonTradeAlgorithm(algorithmAddress);
    }

     function checkUpkeep(bytes calldata checkData)
        override
        public
        returns (bool upkeepNeeded, bytes memory performData)
    {}

    function performUpkeep(bytes calldata performData) override public {}

    function getCurrentPrice() public view returns (uint256) {
        if(totalSupply() == 0) {
            return 10**8;
        }

        uint256 cumulativeValue = 0;
        for(uint256 i = 0; i < _coins.length; i++) {
            IERC20 coin = IERC20(_coins[i].coinAddress);
            cumulativeValue += uint256(_fexonOracle.getCurrentPrice(address(coin))) * coin.balanceOf(address(this)) / 1 ether;
        }
        return cumulativeValue / totalSupply();
    }

    function _buyCoin(TradeData memory data) private {
        address[] memory pool = new address[](2);
        pool[0] = _WBNB;
        pool[1] = data.coin;

        _pancakeRouter.swapExactETHForTokens{value: data.amount}(
            0,
            pool,
            address(this),
            block.timestamp
        );
    }

    function _sellCoin(uint256 amount, address coin) private {
        address[] memory pool = new address[](2);
        pool[0] = coin;
        pool[1] = _WBNB;

        IERC20(coin).approve(address(_pancakeRouter), amount);
        _pancakeRouter.swapExactTokensForETH(
            amount,
            0,
            pool,
            msg.sender,
            block.timestamp
        );
    }

    function _rebalance() private {
        
    }

    function _buildPortfolio() private view returns (Portfolio memory) {
        PortfolioEntry[] memory entries = new PortfolioEntry[](_coins.length);
        for (uint256 i = 0; i < _coins.length; i++) {
            IERC20 coin = IERC20(_coins[i].coinAddress);
            entries[i] = PortfolioEntry(
                address(coin),
                _coins[i].symbol,
                coin.balanceOf(address(this))
            );
        }
        Portfolio memory portfolio = Portfolio(address(this).balance, entries);
        return portfolio;
    }
}
