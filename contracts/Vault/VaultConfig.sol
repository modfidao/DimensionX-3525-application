// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract VaultConfig {
    address public manager;
    uint public manageFee; // 10**18 = 100%

    // transfer manager
    event TransferManager(address from, address to);
    // changed manage fee
    event ChangedManageFee(uint older, uint renew);
    // claim manager fee
    event ClaimManagerFee(address indexed caller, uint amount);

    function _setManager(address manager_) internal onlyManager {
        emit TransferManager(manager, manager_);
        manager = manager_;
    }

    function changeManageFee(uint manageFee_) external onlyManager {
        emit ChangedManageFee(manageFee, manageFee_);
        manageFee = manageFee_;
    }

    modifier onlyManager() {
        require(msg.sender == manager, "ERR_NOT_OWNER");
        _;
    }
}
