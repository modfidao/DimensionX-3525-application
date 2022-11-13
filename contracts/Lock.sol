// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./solvprotocol/erc-3525/ERC3525SlotEnumerableUpgradeable.sol";
import "./Vault/Vault.sol";

contract DimensionX is ERC3525SlotEnumerableUpgradeable, Vault {
    constructor(uint shareSupply_, address manager_, address Platform_) Vault(shareSupply_, manager_, Platform_) {
        _mint(manager_, 1, shareSupply_);
    }

    function initialize(string memory name_, string memory symbol_, uint8 decimals_) public virtual initializer {
        __ERC3525AllRound_init(name_, symbol_, decimals_);
    }

    function __ERC3525AllRound_init(string memory name_, string memory symbol_, uint8 decimals_) internal onlyInitializing {
        __ERC3525_init_unchained(name_, symbol_, decimals_);
    }

    function __ERC3525AllRound_init_unchained() internal onlyInitializing {}

    function composeOrSplitToken(uint fromTokenId_, uint toTokenId_, uint amount_) external {
        (uint fromSlot, uint toSlot) = _soltOfFromAndTo(fromTokenId_, toTokenId_);

        require(toSlot != 0, "ERR_NOT_FOUND_TOKEN");

        uint burnFromTokenAmount = (toSlot * amount_) / fromSlot;
        uint getToTokenAmount = (fromSlot * amount_) / toSlot;

        _burnSlotValue(fromTokenId_, burnFromTokenAmount);
        _mintSlotValue(toTokenId_, getToTokenAmount);
    }

    function addTokenWhite(uint slot_) external onlyManager returns (uint) {
        uint newToken = _mint(manager, slot_, 0);
        return newToken;
    }

    function removeTokenWhite(uint256 tokenId_) external onlyManager {
        require(this.balanceOf(tokenId_) == 0, "ERR_HAS_SHARE_CANT_BURN");
        ERC3525Upgradeable._burn(tokenId_);
    }

    function _userHasShare(address user_) internal virtual override returns (uint) {
        AddressData storage userAssets = _addressData[user_];

        require(userAssets.ownedTokens.length != 0, "ERR_YOU_HAVE_NO_TOKEN");
        
        uint share;

        for(uint i; i < userAssets.ownedTokens.length; i ++){
            uint tokenId = userAssets.ownedTokens[i];

            uint tokenSlot = this.slotOf(tokenId);
            uint balance = this.balanceOf(tokenId);

            share += tokenSlot * balance;
        }

        return share;
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
