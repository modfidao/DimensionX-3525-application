// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./VaultConfig.sol";
import "../Platform/IPlatform.sol";

import "hardhat/console.sol";

contract Vault is VaultConfig {
    uint public contractBalance;
    uint public shareSupply;
    IPlatform public Platform;

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

    // token has reawad total info
    mapping(uint => uint) public tokenHasReward;

    function _initVault(uint shareSupply_, address mananger_, address platform_) internal {
        shareSupply = shareSupply_;
        Platform = IPlatform(platform_);
        _setManager(mananger_);
        _setManageFee(25 * 10 ** 15); //default 2.5%
    }

    event ClaimManagerFeeForPlatform(address indexed caller, uint amount);
    event ClaimManagerFeeForProject(address indexed caller, uint amount);
    event ClaimUserReward(address indexed caller, uint amount);

    function userWithdrew() external lock {
        address user = msg.sender;
        uint withdrewAmount = this.userCouldRewardTotal(user);
        uint manangerForPlatformWithdrewAmount = (Platform.manageFee() * withdrewAmount) / ratioBase;
        uint manangerForProjectWithdrewAmount = (manageFee * withdrewAmount) / ratioBase;
        uint userWithdrewAmount = withdrewAmount - manangerForPlatformWithdrewAmount - manangerForProjectWithdrewAmount;
        console.log("looklook",userWithdrewAmount);
        require(userWithdrewAmount > 0, "ERR_NOT_REWARD");

        (bool isUserSuccess, ) = user.call{value: userWithdrewAmount}("");
        (bool isManagerForPlatformSuccess, ) = Platform.receiver().call{value: manangerForPlatformWithdrewAmount}("");
        (bool isManagerProjectSuccess, ) = payable(manager).call{value: manangerForProjectWithdrewAmount}("");

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
        return _calTokensReward(users_);
    }

    function _calTokensReward(address user_) internal returns (uint) {
        (uint[] memory tokens, uint[] memory shares) = _getRewardTokensAndShare(user_);

        uint rewardTotal;

        for (uint i; i < tokens.length; i++) {
            uint tokenId = tokens[i];
            uint share = shares[i];
            uint waitReward = _calTokenReward(tokenId, share);

            rewardTotal += waitReward;
            _setHasTokenReward(tokenId, waitReward);
        }

        return rewardTotal;
    }

    function _calTokenReward(uint tokenId_, uint share_) internal view returns (uint) {
        uint hasReward = _getTokenHasReward(tokenId_);
        uint totalReward = (_contractBalance() * share_) / shareSupply;

        return totalReward - hasReward;
    }

    function _getRewardTokensAndShare(
        address user_
    ) internal virtual returns (uint[] memory tokens_, uint[] memory share_) {}

    function _setHasTokenReward(uint tokenId_, uint amount_) internal {
        tokenHasReward[tokenId_] += amount_;
    }

    function _getTokenHasReward(uint tokenId_) internal view returns (uint) {
        return tokenHasReward[tokenId_];
    }

    function _setTokenReward(uint tokenId_, uint amount_) internal {
        tokenHasReward[tokenId_] = amount_;
    }

    // vault has native token
    function _contractBalance() internal view returns (uint) {
        return contractBalance;
    }

    fallback() external payable {}

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
