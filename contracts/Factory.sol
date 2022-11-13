// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Main.sol";

contract Factory {
    mapping(address => bool) public isDimensionX;

    function newDimensionX(
        string memory name_,
        string memory symbol_,
        uint8 decimals_,
        uint shareSupply_,
        address manager_,
        address Platform_
    ) external returns (address) {
        DimensionX newInstance = new DimensionX(name_, symbol_, decimals_, shareSupply_, manager_, Platform_);
        address addr = address(newInstance);
        isDimensionX[addr] = true;
        return addr;
    }
}
