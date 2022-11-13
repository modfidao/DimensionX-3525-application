// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IManager {
    event TransferManager(address from, address to);
    event ChangedManageFee(uint older, uint renew);
    event ClaimManagerFee(address indexed caller, uint amount);

    function manager() external returns (address);

    function manageFee() external returns (uint);

    function setManager(address manager_) external;

    function changeManageFee(uint manageFee_) external;

    function withdrew(address mananger_, uint amount_) external;
}
