// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Vault.sol";

contract VaultFactory{
    uint lastSlotIndex;

    // solt => vault
    mapping (uint => address) public _slotOfVault;

    function newVault() external returns(address){
        uint slot = _lastSlotIndex();

        Vault vault = new Vault(slot);
        address vaultAddr = address(vault);

        _slotOfVault[slot] = vaultAddr; 
        
        return vaultAddr;
    }

    function _lastSlotIndex() internal returns(uint){
        lastSlotIndex++;
        return lastSlotIndex;
    }
}