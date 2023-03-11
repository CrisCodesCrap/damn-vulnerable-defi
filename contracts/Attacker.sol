// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

interface IAttacker {
    receive() external payable;
    function startAttack() external;
}

abstract contract Attacker is IAttacker, Ownable {

    error NotImplemented();

    receive() external payable {}
    
    function startAttack() external virtual onlyOwner {
        revert NotImplemented();
    }

}