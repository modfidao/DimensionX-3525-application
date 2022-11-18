// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./solvprotocol/erc-3525/SpanningERC3525SlotEnumerableUpgradeable.sol";
import "./Vault/Vault.sol";
import "./utils/InitLock.sol";

import "@openzeppelin/contracts/utils/Counters.sol";

import "hardhat/console.sol";

contract DimensionX is SpanningERC3525SlotEnumerableUpgradeable, Vault, InitLock {
    mapping(uint => bool) public slotWhite;

    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    function init(
        string memory name_,
        string memory symbol_,
        uint8 decimals_,
        uint shareSupply_,
        address manager_,
        address platform_,
        address delegate_
    ) external _initLock_ {
        _tokenIds.increment();
        _initVault(shareSupply_, manager_, platform_, delegate_);
        __SpanningERC3525_init(name_, symbol_, decimals_, delegate_);
        _mint(getAddressFromLegacy(manager_), _tokenIds.current(), shareSupply_);
        _tokenIds.increment();
    }

    function addSlotWhite(uint slot_) external onlyManager returns (uint) {
        require(slot_ != 0, "ERR_CANT_BE_ZERO");
        slotWhite[slot_] = true;
        return slot_;
    }

    function removeSlotWhite(uint256 slot_) external onlyManager {
        require(slotWhite[slot_], "ERR_HAS_NOT_WHITE");
        slotWhite[slot_] = false;
    }

    function composeOrSplitToken(uint fromTokenId_, uint slot_, uint amount_) external returns (uint) {
        uint fromSlot = this.slotOf(fromTokenId_);

        require(slotWhite[slot_] && slot_ != 0, "ERR_NOT_WHITE_SLOT");

        uint burnFromTokenAmount = amount_;
        uint burnTokenBalance = this.balanceOf(fromTokenId_);
        uint getToTokenAmount = (fromSlot * amount_) / slot_;

        uint newTokenId = _tokenIds.current();
        _mint(spanningMsgSender(), newTokenId, slot_, getToTokenAmount);
        _tokenIds.increment();

        _updateReward(fromTokenId_, burnFromTokenAmount, newTokenId);
        burnTokenBalance == burnFromTokenAmount
            ? _burn(fromTokenId_)
            : _burnSlotValue(fromTokenId_, burnFromTokenAmount);

        return newTokenId;
    }

    function _updateReward(uint fromTokenId_, uint fromTokenAmount, uint toTokenId_) internal {
        uint fromTokenReward = _getTokenHasReward(fromTokenId_);
        uint fromTokenBalance = this.balanceOf(fromTokenId_);

        if (fromTokenAmount != fromTokenBalance) {
            fromTokenReward = (fromTokenReward * fromTokenAmount) / fromTokenBalance;
        }

        _setTokenReward(fromTokenId_, fromTokenReward);
        _setTokenReward(toTokenId_, fromTokenReward);
    }

    function _getRewardTokensAndShare(bytes32 user_) internal virtual override returns (uint[] memory, uint[] memory) {
        AddressData storage userAssets = __addressData(user_);

        uint[] memory tokens = userAssets.ownedTokens;
        uint[] memory shares = new uint[](tokens.length);

        require(tokens.length != 0, "ERR_YOU_HAVE_NO_TOKEN");

        for (uint i; i < tokens.length; i++) {
            uint tokenId = tokens[i];

            uint tokenSlot = this.slotOf(tokenId);
            uint balance = this.balanceOf(tokenId);
            uint share = tokenSlot * balance;
            
            shares[i] = share;
        }

        return (tokens, shares);
    }

    function _burnSlotValue(uint256 tokenId_, uint256 burnValue_) internal {
        require(_isApprovedOrOwner(spanningMsgSender(), tokenId_), "ERC3525: caller is not token owner nor approved");
        ERC3525Upgradeable._burnValue(tokenId_, burnValue_);
    }

    uint256[50] private __gap;
}
