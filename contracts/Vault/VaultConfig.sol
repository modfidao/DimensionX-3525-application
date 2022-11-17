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

    function _setManager(address manager_) internal {
        emit TransferManager(manager, manager_);
        manager = manager_;
    }

    function _setManageFee(uint manageFee_) internal {
        emit ChangedManageFee(manageFee, manageFee_);
        manageFee = manageFee_;
    }

    function changeManager(address manager_) external onlyManager {
        _setManager(manager_);
    }

    function changeManageFee(uint manageFee_) external onlyManager {
        _setManageFee(manageFee_);
    }

    modifier onlyManager() {
        require(msg.sender == manager, "ERR_NOT_MANAGER");
        _;
    }
}
