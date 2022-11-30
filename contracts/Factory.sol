// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {DimensionX} from "./Main.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Factory is Ownable {
    mapping(address => bool) public isDimensionX;
    address public platform;

    function newDimensionX(
        string memory name_,
        string memory symbol_,
        uint8 decimals_,
        uint shareSupply_,
        address manager_
    ) external returns (address) {
        DimensionX newInstance = new DimensionX();
        newInstance.init(name_, symbol_, decimals_, shareSupply_, manager_, platform);
        address addr = address(newInstance);
        isDimensionX[addr] = true;
        return addr;
    }

    function setPlatform(address platform_) external onlyOwner{
        platform = platform_;
    }
}
