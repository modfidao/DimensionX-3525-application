// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./solvprotocol/erc-3525/ERC3525SlotEnumerableUpgradeable.sol";
import "./Vault/Vault.sol";

contract DimensionX is ERC3525SlotEnumerableUpgradeable, Vault {
    // single token has claim reward

    constructor(
        string memory name_,
        string memory symbol_,
        uint8 decimals_,
        uint shareSupply_,
        address manager_,
        address platform_
    ) Vault(shareSupply_, manager_, platform_) {
        _mint(manager_, 1, shareSupply_);
        initialize(name_, symbol_, decimals_);
    }

    function initialize(string memory name_, string memory symbol_, uint8 decimals_) public virtual initializer {
        __ERC3525AllRound_init(name_, symbol_, decimals_);
    }

    function __ERC3525AllRound_init(
        string memory name_,
        string memory symbol_,
        uint8 decimals_
    ) internal onlyInitializing {
        __ERC3525_init_unchained(name_, symbol_, decimals_);
    }

    function __ERC3525AllRound_init_unchained() internal onlyInitializing {}

    function composeOrSplitToken(uint fromTokenId_, uint toTokenId_, uint amount_) external {
        (uint fromSlot, uint toSlot) = _soltOfFromAndTo(fromTokenId_, toTokenId_);

        require(toSlot != 0, "ERR_NOT_FOUND_TOKEN");

        uint burnFromTokenAmount = amount_;
        uint getToTokenAmount = (fromSlot * amount_) / toSlot;

        _updateReward(fromTokenId_, burnFromTokenAmount, toTokenId_);
        _burnSlotValue(fromTokenId_, burnFromTokenAmount);
        _mintSlotValue(toTokenId_, getToTokenAmount);
    }

    function _updateReward(uint fromTokenId_, uint fromTokenAmount, uint toTokenId_) internal {
        uint fromTokenReward = _getTokenHasReward(fromTokenId_);
        uint fromTokenBalance = this.balanceOf(fromTokenAmount);

        if (fromTokenAmount != fromTokenBalance) {
            fromTokenReward = (fromTokenReward * fromTokenAmount) / fromTokenBalance;
        }

        _setTokenReward(fromTokenId_, fromTokenReward);
        _setTokenReward(toTokenId_, fromTokenBalance);
    }

    function addTokenWhite(uint slot_) external onlyManager returns (uint) {
        uint newToken = _mint(manager, slot_, 0);
        return newToken;
    }

    function removeTokenWhite(uint256 tokenId_) external onlyManager {
        require(this.balanceOf(tokenId_) == 0, "ERR_HAS_SHARE_CANT_BURN");
        ERC3525Upgradeable._burn(tokenId_);
    }

    function _getRewardTokensAndShare(address user_) internal virtual override returns (uint[] memory, uint[] memory) {
        AddressData storage userAssets = __addressData(user_);

        uint[] memory tokens = userAssets.ownedTokens;
        uint[] memory shares;

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

    function _mintSlotValue(uint256 tokenId_, uint256 value_) internal {
        ERC3525Upgradeable._mintValue(tokenId_, value_);
    }

    function _burnSlotValue(uint256 tokenId_, uint256 burnValue_) internal {
        require(_isApprovedOrOwner(_msgSender(), tokenId_), "ERC3525: caller is not token owner nor approved");
        ERC3525Upgradeable._burnValue(tokenId_, burnValue_);
    }

    function _soltOfFromAndTo(uint fromTokenId_, uint toTokenId) internal view returns (uint, uint) {
        return (this.slotOf(fromTokenId_), this.slotOf(toTokenId));
    }

    uint256[50] private __gap;
}
