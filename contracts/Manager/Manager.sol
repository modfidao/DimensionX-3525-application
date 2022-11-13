// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IManager.sol";

contract Manager is IManager {
    address public manager;
    uint public manageFee; // 10**18 = 100%

    constructor() {
        manager = msg.sender;
    }

    function setManager(address manager_) external override onlyManager {
        emit TransferManager(manager, manager_);
        manager = manager_;
    }

    function changeManageFee(uint manageFee_) external override onlyManager {
        emit ChangedManageFee(manageFee, manageFee_);
        manageFee = manageFee_;
    }

    // if this contract is reciver
    function withdrew(address mananger_, uint amount_) external override onlyManager {
        require(address(this).balance >= amount_, "ERR_NOT_ENOUGH");
        (bool isSuccess, ) = mananger_.call{value: amount_}("");
        require(isSuccess, "ERR_SYSTEM_ERROR");
    }

    modifier onlyManager() {
        require(msg.sender == manager, "ERR_NOT_OWNER");
        _;
    }

    // if this contract is receiver
    receive() external payable {}
}
