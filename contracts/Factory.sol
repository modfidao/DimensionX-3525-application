// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {DimensionX} from "./Main.sol";

contract Factory {
    mapping(address => bool) public isDimensionX;

    function newDimensionX(
        string memory name_,
        string memory symbol_,
        uint8 decimals_,
        uint shareSupply_,
        address manager_,
        address platform_,
        address delegate_
    ) external returns (address) {
        DimensionX newInstance = new DimensionX();
        newInstance.init(name_, symbol_, decimals_, shareSupply_, manager_, platform_, delegate_);
        address addr = address(newInstance);
        isDimensionX[addr] = true;
        return addr;
    }
}
