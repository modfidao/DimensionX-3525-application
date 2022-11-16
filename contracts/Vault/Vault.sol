// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./VaultConfig.sol";
import "../Platform/IPlatform.sol";

contract Vault is VaultConfig {
    uint public contractBalance;
    uint public shareSupply;
    IPlatform public Plantofrom;

    uint constant ratioBase = 10 ** 18;

    bool _lock; // for safe

    // user info
    struct UserPool {
        uint transferOut;
        uint transferIn;
        uint hasWithdrew;
        uint hasRecived;
        uint hasWithdrewTimes;
    }

    // all user pool
    mapping(address => UserPool) public userPools;

    constructor(uint shareSupply_, address mananger_, address platform_) {
        shareSupply = shareSupply_;
        Plantofrom = IPlatform(platform_);
        manager = mananger_;
    }

    event ClaimManagerFeeForPlatform(address indexed caller, uint amount);
    event ClaimManagerFeeForProject(address indexed caller, uint amount);
    event ClaimUserReward(address indexed caller, uint amount);

    function userWithdrew() external lock {
        address user = msg.sender;
        uint withdrewAmount = this.userCouldRewardTotal(user);

        uint manangerForPlatformWithdrewAmount = (Plantofrom.manageFee() * withdrewAmount) / ratioBase;
        uint manangerForProjectWithdrewAmount = (manageFee * withdrewAmount) / ratioBase;
        uint userWithdrewAmount = withdrewAmount - manangerForPlatformWithdrewAmount - manangerForProjectWithdrewAmount;

        require(userWithdrewAmount > 0, "ERR_NOT_REWARD");

        (bool isUserSuccess, ) = user.call{value: userWithdrewAmount}("");
        (bool isManagerForPlatformSuccess, ) = Plantofrom.receiver().call{value: manangerForPlatformWithdrewAmount}("");
        (bool isManagerProjectSuccess, ) = manager.call{value: manangerForProjectWithdrewAmount}("");

        userPools[user].hasWithdrew += withdrewAmount;
        userPools[user].hasRecived += userWithdrewAmount;
        userPools[user].hasWithdrewTimes++;

        emit ClaimManagerFeeForPlatform(user, manangerForPlatformWithdrewAmount);
        emit ClaimManagerFeeForProject(user, manangerForProjectWithdrewAmount);
        emit ClaimUserReward(user, userWithdrewAmount);

        require(isUserSuccess && isManagerForPlatformSuccess && isManagerProjectSuccess, "ERR_WITHDREW_FAILED");
    }

    // user could reward total
    function userCouldRewardTotal(address users_) external returns (uint) {
        return this.userShouldRewardTotal(users_) - userPools[users_].hasWithdrew;
    }

    // user should reward total
    function userShouldRewardTotal(address user_) external returns (uint) {
        return (_userHasShare(user_) * _contractBalance()) / shareSupply;
    }

    // user has share
    function _userHasShare(address user_) internal virtual returns (uint) {}

    function _whenTransferOut(address user_) internal {}

    function _whenTransfetIn(address user_) internal {}

    // vault has native token
    function _contractBalance() internal view returns (uint) {
        return contractBalance;
    }

    // revive native token
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
