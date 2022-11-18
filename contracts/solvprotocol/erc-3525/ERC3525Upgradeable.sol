// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/introspection/ERC165Upgradeable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@spanning/contracts/token/ERC721/ISpanningERC721.col";
import "@spanning/contracts/token/ERC721/extensions/ISpanningERC721Enumerable.sol";
import "./ISpanningERC3525.sol";
import "./IERC721Receiver.sol";
import "./IERC3525Receiver.sol";
import "./extensions/IERC721Metadata.sol";
import "./extensions/IERC3525Metadata.sol";
import "./periphery/interface/IERC3525MetadataDescriptor.sol";

contract SpanningERC3525Upgradeable is Initializable, ContextUpgradeable, IERC3525Metadata, ISpanningERC721Enumerable {
    using Strings for address;
    using Strings for uint256;
    // This allows us to efficiently unpack data in our address specification.
    using SpanningAddress for bytes32;
    using AddressUpgradeable for address;

    event SetMetadataDescriptor(address indexed metadataDescriptor);

    // TODO
    // nft -> nfts
    struct TokenData {
        uint256 id;
        uint256 slot;
        uint256 balance;
        bytes32 owner;
        bytes32 approved;
        bytes32[] valueApprovals;
    }

    // TODO
    struct AddressData {
        uint256[] ownedTokens;
        mapping(uint256 => uint256) ownedTokensIndex;
        mapping(address => bool) approvals;
    }

    // pool config basic
    string private _name;
    string private _symbol;
    uint8 private _decimals;

    // id => (approval => allowance)
    // @dev _approvedValues cannot be defined within TokenData, cause struct containing mappings cannot be constructed.
    mapping(uint256 => mapping(bytes32 => uint256)) private _approvedValues;

    // tokens and key: id
    TokenData[] private _allTokens;
    mapping(uint256 => uint256) private _allTokensIndex;

    // TODO
    mapping(bytes32 => AddressData) private _addressData;

    // Convenience modifier for common bounds checks
    modifier onlyOwnerOrApproved(uint256 tokenId_) {
        require(
            _isApprovedOrOwner(tokenId_, spanningMsgSender()),
            "onlyOwnerOrApproved: bad role"
        );
        _;
    }

    function __addressData(bytes32 user_) internal view returns (AddressData storage) {
        return _addressData[user_];
    }

    IERC3525MetadataDescriptor public metadataDescriptor;

    // solhint-disable-next-line
    function __ERC3525_init(
        string memory name_, 
        string memory symbol_, 
        uint8 decimals_,
        address _delegate,
        ) internal onlyInitializing {
        __Spanning_init_unchained(_delegate);
        __ERC3525_init_unchained(name_, symbol_, decimals_);
    }

    // solhint-disable-next-line
    function __ERC3525_init_unchained(string memory name_, string memory symbol_, uint8 decimals_) internal onlyInitializing {
        _name = name_;
        _symbol = symbol_;
        _decimals = decimals_;
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return
            interfaceId == type(IERC165).interfaceId ||
            interfaceId == type(IERC3525).interfaceId ||
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC3525Metadata).interfaceId ||
            interfaceId == type(IERC721Enumerable).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId;
    }

    /**
     * @dev Returns the token collection name.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals the token uses for value.
     */
    function valueDecimals() public view virtual override returns (uint8) {
        return _decimals;
    }

    function balanceOf(uint256 tokenId_) public view virtual override returns (uint256) {
        _requireMinted(tokenId_);
        return _allTokens[_allTokensIndex[tokenId_]].balance;
    }

    function ownerOf(uint256 tokenId_) public view virtual override returns (address owner_) {
        _requireMinted(tokenId_);
        owner_ = ownerOfSpanning(tokenId_);
        // To prevent incorrect data leakage, we return the legacy address
        // only if that user is local to the current domain.
        bytes4 ownerDomain = SpanningUpgradeable.getDomainFromAddress(
            ownerAddress
        );
        require(
            ownerDomain == SpanningUpgradeable.getDomain(),
            "SpanningERC3525: remote account requesting legacy address"
        );
        return getLegacyFromAddress(ownerAddress);
    }

    function ownerOfSpanning(uint256 tokenId_) public view virtual override returns (bytes32 owner_) {
        _requireMinted(tokenId_);
        owner_ = _allTokens[_allTokensIndex[tokenId_]].owner;
        require(owner_ != bytes32(0), "ERC3525: invalid token ID");
    }

    function slotOf(uint256 tokenId_) public view virtual override returns (uint256) {
        _requireMinted(tokenId_);
        return _allTokens[_allTokensIndex[tokenId_]].slot;
    }

    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    function contractURI() public view virtual override returns (string memory) {
        string memory baseURI = _baseURI();
        return
            address(metadataDescriptor) != address(0)
                ? metadataDescriptor.constructContractURI()
                : bytes(baseURI).length > 0
                ? string(abi.encodePacked(baseURI, "contract/", Strings.toHexString(address(this))))
                : "";
    }

    function slotURI(uint256 slot_) public view virtual override returns (string memory) {
        string memory baseURI = _baseURI();
        return
            address(metadataDescriptor) != address(0)
                ? metadataDescriptor.constructSlotURI(slot_)
                : bytes(baseURI).length > 0
                ? string(abi.encodePacked(baseURI, "slot/", slot_.toString()))
                : "";
    }

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId_) public view virtual override returns (string memory) {
        _requireMinted(tokenId_);
        string memory baseURI = _baseURI();
        return
            address(metadataDescriptor) != address(0)
                ? metadataDescriptor.constructTokenURI(tokenId_)
                : bytes(baseURI).length > 0
                ? string(abi.encodePacked(baseURI, tokenId_.toString()))
                : "";
    }

    /**
     * @dev See {IERC3525-approve}.
     */
    function approve(uint256 tokenId_, address receiverLegacyAddress_, uint256 value_)
        public
        virtual
        override
    {
        bytes32 receiverAddress = getAddressFromLegacy(receiverLegacyAddress_);
        approve(tokenId_, receiverAddress, value_);
    }

    /**
     * @dev Sets a token allowance for a pair of addresses (sender and receiver).
     *
     * @param tokenId_ - Token allowance to be approved
     * @param receiverAddress_ - Address of the allowance receiver
     * @param value_ - amount to approve
     */
    function approve(uint256 tokenId_, bytes32 receiverAddress_, uint256 value_)
        public
        virtual
        override
        onlyOwnerOrApproved(tokenId_, value_)
    {
        bytes32 tokenOwner = SpanningERC721Upgradeable.ownerOfSpanning(tokenId_);
        require(
            receiverAddress_ != tokenOwner,
            "ERC721: approval to current owner"
        );
        _approve(receiverAddress_, tokenId_, value_);
    }

    function allowance(uint256 tokenId_, address operator_) public view virtual override returns (uint256) {
        _requireMinted(tokenId_);
        return allowance(tokenId_, getAddressFromLegacy(operator_));
    }

    function allowance(uint256 tokenId_, bytes32 operator_) public view virtual override returns (uint256) {
        _requireMinted(tokenId_);
        return _approvedValues[tokenId_][operator_];
    }

    function transferFrom(
        uint256 fromTokenId_,
        address to_,
        uint256 value_
    ) public payable virtual override returns (uint256) {
        return transferFrom(fromTokenId_, getAddressFromLegacy(to_), value_);
    }

    function transferFrom(
        uint256 fromTokenId_,
        bytes32 to_,
        uint256 value_
    ) public payable virtual override returns (uint256) {
        _spendAllowance(spanningMsgSender(), fromTokenId_, value_);

        uint256 newTokenId = _createDerivedTokenId(fromTokenId_);
        _mint(to_, newTokenId, ERC3525Upgradeable.slotOf(fromTokenId_), 0);
        _transferValue(fromTokenId_, newTokenId, value_);

        return newTokenId;
    }

    function transferFrom(uint256 fromTokenId_, uint256 toTokenId_, uint256 value_) public payable virtual override {
        _spendAllowance(spanningMsgSender(), fromTokenId_, value_);
        _transferValue(fromTokenId_, toTokenId_, value_);
    }

    function balanceOf(address owner_) public view virtual override returns (uint256 balance) {
        return balanceOf(getAddressFromLegacy(owner_));
    }

    function balanceOf(bytes32 owner_) public view virtual override returns (uint256 balance) {
        require(owner_ != bytes32(0), "ERC3525: balance query for the zero address");
        return _addressData[owner_].ownedTokens.length;
    }

    function transferFrom(address from_, address to_, uint256 tokenId_) public payable virtual override {
        transferFrom(getAddressFromLegacy(from_),getAddressFromLegacy(to_), tokenId_)
    }

    function transferFrom(bytes32 from_, bytes32 to_, uint256 tokenId_) public payable virtual override {
        require(_isApprovedOrOwner(spanningMsgSender(), tokenId_), "ERC3525: transfer caller is not owner nor approved");
        _transferTokenId(from_, to_, tokenId_);
    }

    function safeTransferFrom(
        address from_,
        address to_,
        uint256 tokenId_,
        bytes memory data_
    ) public payable virtual override {
        safeTransferFrom(getAddressFromLegacy(from_), getAddressFromLegacy(to_), tokenId_, data_);
    }

    function safeTransferFrom(
        bytes32 from_,
        bytes32 to_,
        uint256 tokenId_,
        bytes memory data_
    ) public payable virtual override {
        require(_isApprovedOrOwner(spanningMsgSender(), tokenId_), "ERC3525: transfer caller is not owner nor approved");
        _safeTransferTokenId(from_, to_, tokenId_, data_);
    }

    function safeTransferFrom(address from_, address to_, uint256 tokenId_) public payable virtual override {
        safeTransferFrom(from_, to_, tokenId_, "");
    }

    function safeTransferFrom(bytes32 from_, bytes32 to_, uint256 tokenId_) public payable virtual override {
        safeTransferFrom(from_, to_, tokenId_, "");
    }

    function approve(address to_, uint256 tokenId_) public payable virtual override {
        approve(getAddressFromLegacy(to_), tokenId_);
    }

    function approve(bytes32 to_, uint256 tokenId_) public payable virtual override {
        address owner = ERC3525Upgradeable.ownerOf(tokenId_);
        require(to_ != owner, "ERC3525: approval to current owner");

        require(
            spanningMsgSender() == owner || ERC3525Upgradeable.isApprovedForAll(owner, spanningMsgSender()),
            "ERC3525: approve caller is not owner nor approved for all"
        );

        _approve(to_, tokenId_);
    }

    function getApproved(uint256 tokenId_) public view virtual override returns (address) {
        _requireMinted(tokenId_);
        return _allTokens[_allTokensIndex[tokenId_]].approved;
    }

    function setApprovalForAll(address operator_, bool approved_) public virtual override {
        setApprovalForAll(getAddressFromLegacy(operator_), approved_);
    }

    function setApprovalForAll(bytes32 operator_, bool approved_) public virtual override {
        _setApprovalForAll(spanningMsgSender(), operator_, approved_);
    }

    function isApprovedForAll(address owner_, address operator_) public view virtual override returns (bool) {
        return isApprovedForAll(getAddressFromLegacy(owner_), getAddressFromLegacy(operator_));
    }

    function isApprovedForAll(bytes32 owner_, bytes32 operator_) public view virtual override returns (bool) {
        return _addressData[owner_].approvals[operator_];
    }

    function totalSupply() public view virtual override returns (uint256) {
        return _allTokens.length;
    }

    function tokenByIndex(uint256 index_) public view virtual override returns (uint256) {
        require(index_ < ERC3525Upgradeable.totalSupply(), "ERC3525: global index out of bounds");
        return _allTokens[index_].id;
    }

    function tokenOfOwnerByIndex(address owner_, uint256 index_) public view virtual override returns (uint256) {
        return tokenOfOwnerByIndex(getAddressFromLegacy(owner_), index_);
    }

    function tokenOfOwnerByIndex(bytes32 owner_, uint256 index_) public view virtual override returns (uint256) {
        require(index_ < ERC3525Upgradeable.balanceOf(owner_), "ERC3525: owner index out of bounds");
        return _addressData[owner_].ownedTokens[index_];
    }

    function _setApprovalForAll(bytes32 owner_, bytes32 operator_, bool approved_) internal virtual {
        require(owner_ != operator_, "ERC3525: approve to caller");

        _addressData[owner_].approvals[operator_] = approved_;

        emit ApprovalForAll(owner_, operator_, approved_);
    }

    function _isApprovedOrOwner(bytes32 operator_, uint256 tokenId_) internal view virtual returns (bool) {
        _requireMinted(tokenId_);
        address owner = SpanningERC3525Upgradeable.ownerOfSpanning(tokenId_);
        return (operator_ == owner ||
            SpanningERC3525Upgradeable.isApprovedForAll(owner, operator_) ||
            SpanningERC3525Upgradeable.getApproved(tokenId_) == operator_);
    }

    function _spendAllowance(bytes32 operator_, uint256 tokenId_, uint256 value_) internal virtual {
        uint256 currentAllowance = ERC3525Upgradeable.allowance(tokenId_, operator_);
        if (!_isApprovedOrOwner(operator_, tokenId_) && currentAllowance != type(uint256).max) {
            require(currentAllowance >= value_, "ERC3525: insufficient allowance");
            _approveValue(tokenId_, operator_, currentAllowance - value_);
        }
    }

    function _exists(uint256 tokenId_) internal view virtual returns (bool) {
        return _allTokens.length != 0 && _allTokens[_allTokensIndex[tokenId_]].id == tokenId_;
    }

    function _requireMinted(uint256 tokenId_) internal view virtual {
        require(_exists(tokenId_), "ERC3525: invalid token ID");
    }

    function _mint(bytes32 to_, uint256 slot_, uint256 value_) internal virtual returns (uint256) {
        uint256 tokenId = _createOriginalTokenId();
        _mint(to_, tokenId, slot_, value_);
        return tokenId;
    }

    function _mint(bytes32 to_, uint256 tokenId_, uint256 slot_, uint256 value_) internal virtual {
        require(to_ != bytes32(0), "ERC3525: mint to the zero address");
        require(tokenId_ != 0, "ERC3525: cannot mint zero tokenId");
        require(!_exists(tokenId_), "ERC3525: token already minted");

        _beforeValueTransfer(bytes32(0), to_, 0, tokenId_, slot_, value_);
        __mintToken(to_, tokenId_, slot_);
        __mintValue(tokenId_, value_);
        _afterValueTransfer(bytes32(0), to_, 0, tokenId_, slot_, value_);
    }

    function _mintValue(uint256 tokenId_, uint256 value_) internal virtual {
        _requireMinted(tokenId_);

        address owner = ERC3525Upgradeable.ownerOf(tokenId_);
        uint256 slot = ERC3525Upgradeable.slotOf(tokenId_);
        _beforeValueTransfer(bytes32(0), owner, 0, tokenId_, slot, value_);
        __mintValue(tokenId_, value_);
        _afterValueTransfer(bytes32(0), owner, 0, tokenId_, slot, value_);
    }

    function __mintValue(uint256 tokenId_, uint256 value_) private {
        _allTokens[_allTokensIndex[tokenId_]].balance += value_;
        emit TransferValue(0, tokenId_, value_);
    }

    function __mintToken(bytes32 to_, uint256 tokenId_, uint256 slot_) private {
        TokenData memory tokenData = TokenData({
            id: tokenId_,
            slot: slot_,
            balance: 0,
            owner: to_,
            approved: bytes32(0),
            valueApprovals: new bytes32[](0)
        });

        _addTokenToAllTokensEnumeration(tokenData);
        _addTokenToOwnerEnumeration(to_, tokenId_);

        emit Transfer(bytes32(0), to_, tokenId_);
        emit SlotChanged(tokenId_, 0, slot_);
    }

    function _burn(uint256 tokenId_) internal virtual {
        _requireMinted(tokenId_);

        TokenData storage tokenData = _allTokens[_allTokensIndex[tokenId_]];
        bytes32 owner = tokenData.owner;
        uint256 slot = tokenData.slot;
        uint256 value = tokenData.balance;

        _beforeValueTransfer(owner, bytes32(0), tokenId_, 0, slot, value);

        _clearApprovedValues(tokenId_);
        _removeTokenFromOwnerEnumeration(owner, tokenId_);
        _removeTokenFromAllTokensEnumeration(tokenId_);

        emit TransferValue(tokenId_, 0, value);
        emit SlotChanged(tokenId_, slot, 0);
        emit Transfer(owner, bytes32(0), tokenId_);

        _afterValueTransfer(owner, bytes32(0), tokenId_, 0, slot, value);
    }

    function _burnValue(uint256 tokenId_, uint256 burnValue_) internal virtual {
        _requireMinted(tokenId_);

        TokenData storage tokenData = _allTokens[_allTokensIndex[tokenId_]];
        bytes32 owner = tokenData.owner;
        uint256 slot = tokenData.slot;
        uint256 value = tokenData.balance;

        require(value >= burnValue_, "ERC3525: burn value exceeds balance");

        _beforeValueTransfer(owner, bytes32(0), tokenId_, 0, slot, burnValue_);

        tokenData.balance -= burnValue_;
        emit TransferValue(tokenId_, 0, burnValue_);

        _afterValueTransfer(owner, bytes32(0), tokenId_, 0, slot, burnValue_);
    }

    function _addTokenToOwnerEnumeration(bytes32 to_, uint256 tokenId_) private {
        _allTokens[_allTokensIndex[tokenId_]].owner = to_;

        _addressData[to_].ownedTokensIndex[tokenId_] = _addressData[to_].ownedTokens.length;
        _addressData[to_].ownedTokens.push(tokenId_);
    }

    function _removeTokenFromOwnerEnumeration(bytes32 from_, uint256 tokenId_) private {
        _allTokens[_allTokensIndex[tokenId_]].owner = bytes32(0);

        AddressData storage ownerData = _addressData[from_];
        uint256 lastTokenIndex = ownerData.ownedTokens.length - 1;
        uint256 lastTokenId = ownerData.ownedTokens[lastTokenIndex];
        uint256 tokenIndex = ownerData.ownedTokensIndex[tokenId_];

        ownerData.ownedTokens[tokenIndex] = lastTokenId;
        ownerData.ownedTokensIndex[lastTokenId] = tokenIndex;

        delete ownerData.ownedTokensIndex[tokenId_];
        ownerData.ownedTokens.pop();
    }

    function _addTokenToAllTokensEnumeration(TokenData memory tokenData_) private {
        _allTokensIndex[tokenData_.id] = _allTokens.length;
        _allTokens.push(tokenData_);
    }

    function _removeTokenFromAllTokensEnumeration(uint256 tokenId_) private {
        // To prevent a gap in the tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = _allTokens.length - 1;
        uint256 tokenIndex = _allTokensIndex[tokenId_];

        // When the token to delete is the last token, the swap operation is unnecessary. However, since this occurs so
        // rarely (when the last minted token is burnt) that we still do the swap here to avoid the gas cost of adding
        // an 'if' statement (like in _removeTokenFromOwnerEnumeration)
        TokenData memory lastTokenData = _allTokens[lastTokenIndex];

        _allTokens[tokenIndex] = lastTokenData; // Move the last token to the slot of the to-delete token
        _allTokensIndex[lastTokenData.id] = tokenIndex; // Update the moved token's index

        // This also deletes the contents at the last position of the array
        delete _allTokensIndex[tokenId_];
        _allTokens.pop();
    }

    function _approve(bytes32 to_, uint256 tokenId_) internal virtual {
        _allTokens[_allTokensIndex[tokenId_]].approved = to_;
        emit Approval(ERC3525Upgradeable.ownerOf(tokenId_), to_, tokenId_);
    }

    function _approveValue(uint256 tokenId_, address to_, uint256 value_) internal virtual {
        require(to_ != bytes32(0), "ERC3525: approve value to the zero address");
        if (!_existApproveValue(to_, tokenId_)) {
            _allTokens[_allTokensIndex[tokenId_]].valueApprovals.push(to_);
        }
        _approvedValues[tokenId_][to_] = value_;

        emit ApprovalValue(tokenId_, to_, value_);
    }

    function _clearApprovedValues(uint256 tokenId_) internal virtual {
        TokenData storage tokenData = _allTokens[_allTokensIndex[tokenId_]];
        uint256 length = tokenData.valueApprovals.length;
        for (uint256 i = 0; i < length; i++) {
            bytes32 approval = tokenData.valueApprovals[i];
            delete _approvedValues[tokenId_][approval];
        }
    }

    function _existApproveValue(bytes32 to_, uint256 tokenId_) internal view virtual returns (bool) {
        uint256 length = _allTokens[_allTokensIndex[tokenId_]].valueApprovals.length;
        for (uint256 i = 0; i < length; i++) {
            if (_allTokens[_allTokensIndex[tokenId_]].valueApprovals[i] == to_) {
                return true;
            }
        }
        return false;
    }

    function _transferValue(uint256 fromTokenId_, uint256 toTokenId_, uint256 value_) internal virtual {
        require(_exists(fromTokenId_), "ERC3525: transfer from invalid token ID");
        require(_exists(toTokenId_), "ERC3525: transfer to invalid token ID");

        TokenData storage fromTokenData = _allTokens[_allTokensIndex[fromTokenId_]];
        TokenData storage toTokenData = _allTokens[_allTokensIndex[toTokenId_]];

        require(fromTokenData.balance >= value_, "ERC3525: insufficient balance for transfer");
        require(fromTokenData.slot == toTokenData.slot, "ERC3525: transfer to token with different slot");

        _beforeValueTransfer(
            fromTokenData.owner,
            toTokenData.owner,
            fromTokenId_,
            toTokenId_,
            fromTokenData.slot,
            value_
        );

        fromTokenData.balance -= value_;
        toTokenData.balance += value_;

        emit TransferValue(fromTokenId_, toTokenId_, value_);

        _afterValueTransfer(
            fromTokenData.owner,
            toTokenData.owner,
            fromTokenId_,
            toTokenId_,
            fromTokenData.slot,
            value_
        );

        require(
            _checkOnERC3525Received(fromTokenId_, toTokenId_, value_, ""),
            "ERC3525: transfer to non ERC3525Receiver"
        );
    }

    function _transferTokenId(bytes32 from_, bytes32 to_, uint256 tokenId_) internal virtual {
        require(ERC3525Upgradeable.ownerOf(tokenId_) == from_, "ERC3525: transfer from invalid owner");
        require(to_ != bytes32(0), "ERC3525: transfer to the zero address");

        uint256 slot = ERC3525Upgradeable.slotOf(tokenId_);
        uint256 value = ERC3525Upgradeable.balanceOf(tokenId_);

        _beforeValueTransfer(from_, to_, tokenId_, tokenId_, slot, value);

        _approve(bytes32(0), tokenId_);
        _clearApprovedValues(tokenId_);

        _removeTokenFromOwnerEnumeration(from_, tokenId_);
        _addTokenToOwnerEnumeration(to_, tokenId_);

        emit Transfer(from_, to_, tokenId_);

        _afterValueTransfer(from_, to_, tokenId_, tokenId_, slot, value);
    }

    function _safeTransferTokenId(bytes32 from_, bytes32 to_, uint256 tokenId_, bytes memory data_) internal virtual {
        _transferTokenId(from_, to_, tokenId_);
        require(_checkOnERC721Received(from_, to_, tokenId_, data_), "ERC3525: transfer to non ERC721Receiver");
    }

    function _checkOnERC3525Received(
        uint256 fromTokenId_,
        uint256 toTokenId_,
        uint256 value_,
        bytes memory data_
    ) private returns (bool) {
        address to = ERC3525Upgradeable.ownerOf(toTokenId_);
        if (to.isContract() && IERC165(to).supportsInterface(type(IERC3525Receiver).interfaceId)) {
            try IERC3525Receiver(to).onERC3525Received(getLegacyFromAddress(spanningMsgSender()), fromTokenId_, toTokenId_, value_, data_) returns (
                bytes4 retval
            ) {
                return retval == IERC3525Receiver.onERC3525Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC3525: transfer to non ERC3525Receiver");
                } else {
                    // solhint-disable-next-line
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from_ address representing the previous owner of the given token ID
     * @param to_ target address that will receive the tokens
     * @param tokenId_ uint256 ID of the token to be transferred
     * @param data_ bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        bytes32 from_,
        bytes32 to_,
        uint256 tokenId_,
        bytes memory data_
    ) private returns (bool) {
        if (to_.isContract() && IERC165(to_).supportsInterface(type(IERC721Receiver).interfaceId)) {
            try IERC721Receiver(to_).onERC721Received(getLegacyFromAddress(spanningMsgSender()), from_, tokenId_, data_) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver");
                } else {
                    // solhint-disable-next-line
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    /* solhint-disable */
    function _beforeValueTransfer(
        bytes32 from_,
        bytes32 to_,
        uint256 fromTokenId_,
        uint256 toTokenId_,
        uint256 slot_,
        uint256 value_
    ) internal virtual {}

    function _afterValueTransfer(
        bytes32 from_,
        bytes32 to_,
        uint256 fromTokenId_,
        uint256 toTokenId_,
        uint256 slot_,
        uint256 value_
    ) internal virtual {}

    /* solhint-enable */

    function _setMetadataDescriptor(address metadataDescriptor_) internal virtual {
        metadataDescriptor = IERC3525MetadataDescriptor(metadataDescriptor_);
        emit SetMetadataDescriptor(metadataDescriptor_);
    }

    function _createOriginalTokenId() internal virtual returns (uint256) {
        return _createDefaultTokenId();
    }

    function _createDerivedTokenId(uint256 fromTokenId_) internal virtual returns (uint256) {
        fromTokenId_;
        return _createDefaultTokenId();
    }

    function _createDefaultTokenId() private view returns (uint256) {
        return ERC3525Upgradeable.totalSupply() + 1;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     */
    uint256[42] private __gap;
}
