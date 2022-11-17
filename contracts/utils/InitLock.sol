// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract InitLock {
    bool hasInit;

    event InitLog(address caller, address proj, bytes data);

    modifier _initLock_() {
        require(hasInit == false, "ERR_INITIALIZED");
        _;
        hasInit = true;
        emit InitLog(msg.sender, address(this), msg.data);
    }
}
