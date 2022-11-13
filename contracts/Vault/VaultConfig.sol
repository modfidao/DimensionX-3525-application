// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract VaultConfig {
    address public owner;
    uint public manageFee;

    // 移交owenr
    event TransferOwner(address from, address to);
    // 修改管理费
    event ChangedManageFee(uint older, uint renew);

    function _setOwner(address owner_) internal onlyOwner {
        emit TransferOwner(owner, owner_);
        owner = owner_;
    }

    function _changeManageFee(uint manageFee_) internal onlyOwner {
        emit ChangedManageFee(manageFee, manageFee_);
        manageFee = manageFee_;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "ERR_NOT_OWNER");
        _;
    }
}
