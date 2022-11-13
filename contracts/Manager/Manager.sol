// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IManager.sol";

contract Manager is IManager {
    address public manager;
    uint public manageFee; // 10**18 = 100%

    constructor(){
        manager = msg.sender;
    }
    function setManager(address manager_) external onlyManager override {
        emit TransferManager(manager, manager_);
        manager = manager_;
    }

    function changeManageFee(uint manageFee_) external onlyManager override {
        emit ChangedManageFee(manageFee, manageFee_);
        manageFee = manageFee_;
    }

    modifier onlyManager() {
        require(msg.sender == manager, "ERR_NOT_OWNER");
        _;
    }
}
