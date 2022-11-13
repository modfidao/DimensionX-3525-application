// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../@solvprotocol/erc-3525/IERC3525.sol";

contract Vault {
    uint public slot;

    IERC3525 factory;

    // user info
    struct UserPool {
        uint hasWithdrew;
        uint waittingWithdrew;
    }

    // all user pool
    mapping(address => UserPool) userPools;

    constructor(uint slot_, address _factory) {
        slot = slot_;
        factory = IERC3525(_factory);
    }

    function supply(uint tokenId_) external view returns (uint) {
        return factory.balanceOf(tokenId_);
    }

    // receive native token
    fallback() external payable {}

    receive() external payable {}
}
