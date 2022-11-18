// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@spanning/contracts/SpanningUtils.sol";
import "@spanning/contracts/SpanningUpgradeable.sol";

import "./VaultConfig.sol";
import "../Platform/IPlatform.sol";

import "hardhat/console.sol";

contract Vault is VaultConfig, SpanningUpgradeable {
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
    mapping(bytes32 => UserPool) public userPools;

    // token has reawad total info
    mapping(uint => uint) public tokenHasReward;

    function _initVault(uint shareSupply_, address mananger_, address platform_, address delegate_) internal {
        shareSupply = shareSupply_;
        Platform = IPlatform(platform_);
        _setManager(mananger_);
        _setManageFee(25 * 10 ** 15); //default 2.5%
        __Spanning_init_unchained(delegate_);
    }

    event ClaimManagerFeeForPlatform(bytes32 indexed caller, uint amount);
    event ClaimManagerFeeForProject(bytes32 indexed caller, uint amount);
    event ClaimUserReward(bytes32 indexed caller, uint amount);

    function userWithdrew() external lock {
        bytes32 user = spanningMsgSender();
        uint withdrewAmount = this.userCouldRewardTotal(user);
        uint manangerForPlatformWithdrewAmount = (Platform.manageFee() * withdrewAmount) / ratioBase;
        uint manangerForProjectWithdrewAmount = (manageFee * withdrewAmount) / ratioBase;
        uint userWithdrewAmount = withdrewAmount - manangerForPlatformWithdrewAmount - manangerForProjectWithdrewAmount;
        console.log("looklook",userWithdrewAmount);
        require(userWithdrewAmount > 0, "ERR_NOT_REWARD");

        // what is the intended purpose here? Calling the fallback function on a EOA address will always
        // return True I believe - note from Drew
        // (bool isUserSuccess, ) = user.call{value: userWithdrewAmount}("");

        (bool isManagerForPlatformSuccess, ) = Platform.receiver().call{value: manangerForPlatformWithdrewAmount}("");
        (bool isManagerProjectSuccess, ) = payable(manager).call{value: manangerForProjectWithdrewAmount}("");
        console.log("magic",withdrewAmount);
        console.log("magic",userWithdrewAmount);
        userPools[user].hasWithdrew += withdrewAmount;
        userPools[user].hasRecived += userWithdrewAmount;
        userPools[user].hasWithdrewTimes++;

        emit ClaimManagerFeeForPlatform(user, manangerForPlatformWithdrewAmount);
        emit ClaimManagerFeeForProject(user, manangerForProjectWithdrewAmount);
        emit ClaimUserReward(user, userWithdrewAmount);

        require(/*isUserSuccess &&*/ isManagerForPlatformSuccess && isManagerProjectSuccess, "ERR_WITHDREW_FAILED");
    }

    // user could reward total
    function userCouldRewardTotal(bytes32 users_) external returns (uint) {
        return _calTokensReward(users_);
    }

    function userCouldRewardTotal(address users_) external returns (uint) {
        return _calTokensReward(getAddressFromLegacy(users_));
    }

    function _calTokensReward(bytes32 user_) internal returns (uint) {
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
        bytes32 user_
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
