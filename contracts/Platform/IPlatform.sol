// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IPlatform {
    event TransferReciver(address from, address to);
    event TransferOwner(address from, address to);
    event ChangedManageFee(uint older, uint renew);
    event ClaimManagerFee(address indexed caller, uint amount);

    function receiver() external view returns (address);

    function manageFee() external view returns (uint);

    function setOwner(address manager_) external;

    function setReceiver(address manager_) external;

    function changeManageFee(uint manageFee_) external;

    function withdrew(address mananger_, uint amount_) external;
}
