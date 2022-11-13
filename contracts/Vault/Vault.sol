// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./VaultConfig.sol";
import "../Manager/IManager.sol";

contract Vault is VaultConfig {
    uint public contractBalance;
    uint public shareSupply;
    IManager public Manager;

    bool _lock; // for safe

    // user info
    struct UserPool {
        uint hasWithdrew;
        uint hasWithdrewTimes;
    }

    // all user pool
    mapping(address => UserPool) public userPools;

    constructor(uint shareSupply_, address Manager_){
        shareSupply = shareSupply_;
        Manager =  IManager(Manager_);
        manager = msg.sender;
    }

    event ClaimManagerFeeForPlatform(address indexed caller,uint amount);
    event ClaimManagerFeeForProject(address indexed caller,uint amount);
    event ClaimUserReward(address indexed caller, uint amount);

    function userWithdrew() external lock {
        address user = msg.sender;
        uint withdrewAmount = this.userCouldRewardTotal(user);

        uint manangerForPlatformWithdrewAmount = Manager.manageFee() * withdrewAmount / 10**18;
        uint manangerForProjectWithdrewAmount = manageFee * withdrewAmount / 10**18;
        uint userWithdrewAmount = withdrewAmount - manangerForPlatformWithdrewAmount - manangerForProjectWithdrewAmount;

        require(userWithdrewAmount>0,"ERR_NOT_REWARD");

        (bool isUserSuccess, ) = user.call{value: userWithdrewAmount}("");
        (bool isManagerForPlatformSuccess, ) = Manager.manager().call{value: manangerForPlatformWithdrewAmount}("");
        (bool isManagerProjectSuccess, ) = manager.call{value: manangerForProjectWithdrewAmount}("");

        userPools[user].hasWithdrew += userWithdrewAmount;
        userPools[user].hasWithdrewTimes++;

        emit ClaimManagerFeeForPlatform(user,manangerForPlatformWithdrewAmount);
        emit ClaimManagerFeeForProject(user, manangerForProjectWithdrewAmount);
        emit ClaimUserReward(user,userWithdrewAmount);

        require(isUserSuccess && isManagerForPlatformSuccess && isManagerProjectSuccess,"ERR_WITHDREW_FAILED");
    }

    // user could reward total
    function userCouldRewardTotal(address users_) external returns (uint) {
        return this.userShouldRewardTotal(users_) - userPools[users_].hasWithdrew;
    }

    // user should reward total
    function userShouldRewardTotal(address user_) external  returns (uint) {
        return _userHasShare(user_) * _contractBalance() / _userHasShare(user_);
    }

    // user has share
    function _userHasShare(address user_) internal virtual returns(uint){ }

    // vault has native token
    function _contractBalance() internal view returns(uint){
        return contractBalance;
    }

    // receive native token
    fallback() external payable {}

    receive() external payable {
        contractBalance += msg.value;
    }

    modifier lock() {
        require(_lock == false, "ERR_NOT_SAFE");
        _lock = true;
        _;
        _lock = false;
    }
}
