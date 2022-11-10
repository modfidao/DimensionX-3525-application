// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Vault {
    uint public slot;

    constructor(uint slot_){
        slot = slot_;
    }
}
