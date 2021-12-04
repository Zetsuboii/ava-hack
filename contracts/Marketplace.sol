// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

// Tokens
import "./tokens/ARENA.sol";
import "./tokens/SONS.sol";
import "./tokens/GOD.sol";

enum TokenType {
    SONS,
    BILIRA
}

enum AssetType {
    ARENA,
    GOD
}

struct ListingDetails {
    bool initialized;
    AssetType asset;
    TokenType token;
    uint16 amount;
    address owner;
    uint256 assetId; // Type for ERC1155, ID for ERC721
    uint256 price;
}

contract Marketplace {
    using EnumerableSet for EnumerableSet.UintSet;

    address biliraAddress;
    address snsAddress;

    ARENA arenaContract;
    GOD godContract;

    uint256 nonce = 0;
    EnumerableSet.UintSet private listings;
    mapping(uint256 => ListingDetails) public idToListingDetails;
    mapping(address => mapping(uint256 => uint256)) private godListings;

    constructor(
        ARENA arenaAddress,
        GOD godAddress,
        address sons,
        address bilira
    ) {
        snsAddress = sons;
        biliraAddress = bilira;
        arenaContract = ARENA(arenaAddress);
        godContract = GOD(godAddress);
    }

    function getAllListings() external view returns (ListingDetails[] memory) {
        ListingDetails[] memory results = new ListingDetails[](
            listings.length()
        );
        for (uint256 i = 0; i < listings.length(); i++) {
            results[i] = idToListingDetails[listings.at(i)];
        }

        return results;
    }

    // ######### ARENA ######### //

    function listArena(
        uint256 arenaId,
        TokenType token,
        uint256 price
    ) external {
        uint256 listingId = uint256(keccak256(abi.encode(arenaId)));

        require(
            arenaContract.ownerOf(arenaId) == msg.sender,
            "Account not owner of NFT"
        );
        require(
            !idToListingDetails[listingId].initialized,
            "Board is already listed"
        );

        idToListingDetails[listingId] = ListingDetails({
            initialized: true,
            amount: 1,
            asset: AssetType.ARENA,
            assetId: arenaId,
            owner: msg.sender,
            token: token,
            price: price
        });

        listings.add(listingId);
    }

    function removeListing(uint256 listingId) external {
        ListingDetails memory details = idToListingDetails[listingId];

        require(details.initialized, "Listing doesn't exist");

        require(details.owner == msg.sender, "Account not owner of NFT");

        if (details.asset == AssetType.ARENA)
            godListings[msg.sender][details.assetId] -= details.amount;

        delete idToListingDetails[listingId];
        listings.remove(listingId);
    }

    // ######### GODS ######### //

    function listGod(
        uint256 cardType,
        uint16 amount,
        TokenType token,
        uint256 price
    ) external {
        require(
            godContract.isApprovedForAll(msg.sender, address(this)),
            "Contract isn't approved"
        );

        require(
            godContract.balanceOf(msg.sender, cardType) -
                godListings[msg.sender][cardType] >=
                amount,
            "User doesn't have enough cards"
        );
        uint256 listingId = uint256(
            keccak256(abi.encodePacked(amount, cardType, msg.sender))
        );

        require(
            !idToListingDetails[listingId].initialized,
            "This listing already exists"
        );

        idToListingDetails[listingId] = ListingDetails({
            initialized: true,
            assetId: cardType,
            asset: AssetType.GOD,
            owner: msg.sender,
            token: token,
            price: price,
            amount: amount
        });

        godListings[msg.sender][cardType] += amount;
        listings.add(listingId);
    }

    function buyListing(uint256 listingId) external {
        ListingDetails memory details = idToListingDetails[listingId];

        require(details.initialized, "Listing doesn't exist");

        IERC20 tokenToPay = IERC20(
            details.token == TokenType.BILIRA ? biliraAddress : snsAddress
        );

        require(
            tokenToPay.transferFrom(msg.sender, address(this), details.price),
            "Token transfer failed"
        );

        if (details.asset == AssetType.ARENA) {
            arenaContract.transferFrom(
                details.owner,
                msg.sender,
                details.assetId
            );
        } else if (details.asset == AssetType.GOD) {
            godContract.safeTransferFrom(
                details.owner,
                msg.sender,
                details.assetId,
                details.amount,
                ""
            );

            godListings[details.owner][details.assetId] -= details.amount;
        }

        delete idToListingDetails[listingId];
        listings.remove(listingId);
    }
}
