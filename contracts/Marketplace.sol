// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

// Tokens
import "./tokens/ARENA.sol";
import "./tokens/SONS.sol";
import "./tokens/GOD.sol";

enum TokenType {
    FLASH,
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
    address flashAddress;

    AREAN arenaContract;
    SONS snsContract;
    GOD playerContract;

    uint256 nonce = 0;
    EnumerableSet.UintSet private listings;
    mapping(uint256 => ListingDetails) public idToListingDetails;
    mapping(address => mapping(uint256 => uint256))
        private addressToPlayerListings;

    constructor(
        BOARD boardAddress,
        address tokenAddress,
        GOD playerAddress
    ) {
        flashAddress = tokenAddress;
        boardContract = BOARD(boardAddress);
        playerContract = GOD(playerAddress);
    }

    function getAllListings() external view returns (uint256[] memory results) {
        for (uint256 i = 0; i < listings.length(); i++) {
            results[i] = listings.at(i);
        }
    }

    function listBoard(
        uint256 boardId,
        TokenType token,
        uint256 price
    ) external {
        uint256 listingId = uint256(keccak256(abi.encode(boardId)));

        require(
            boardContract.ownerOf(boardId) == msg.sender,
            "Account not owner of NFT"
        );
        require(
            !idToListingDetails[listingId].initialized,
            "Board is already listed"
        );

        idToListingDetails[listingId] = ListingDetails({
            initialized: true,
            amount: 1,
            asset: AssetType.BOARD,
            assetId: boardId,
            owner: msg.sender,
            token: token,
            price: price
        });

        listings.add(listingId);
    }

    function delistBoard(uint256 listingId) external {
        require(
            idToListingDetails[listingId].initialized,
            "Listing doesn't exist"
        );

        require(
            idToListingDetails[listingId].owner == msg.sender,
            "Account not owner of NFT"
        );

        delete idToListingDetails[listingId];
        listings.remove(listingId);
    }

    // PLAYER

    function listPlayer(
        uint256 cardType,
        uint16 amount,
        TokenType token,
        uint256 price
    ) external {
        require(
            playerContract.isApprovedForAll(msg.sender, address(this)),
            "Contract isn't approved"
        );

        require(
            playerContract.balanceOf(msg.sender, cardType) -
                addressToPlayerListings[msg.sender][cardType] <=
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
            asset: AssetType.PLAYER,
            owner: msg.sender,
            token: token,
            price: price,
            amount: amount
        });

        addressToPlayerListings[msg.sender][cardType] += amount;
        listings.add(listingId);
    }

    function delistPlayer(uint256 listingId) external {
        ListingDetails memory details = idToListingDetails[listingId];

        require(details.initialized, "Listing doesn't exist");

        require(details.owner == msg.sender, "Account not owner of NFT");

        addressToPlayerListings[msg.sender][details.assetId] -= details.amount;

        delete idToListingDetails[listingId];
        listings.remove(listingId);
    }

    function buyListing(uint256 listingId) external {
        ListingDetails memory details = idToListingDetails[listingId];

        require(details.initialized, "Listing doesn't exist");

        IERC20 tokenToPay = IERC20(
            details.token == TokenType.BILIRA ? biliraAddress : flashAddress
        );

        require(
            tokenToPay.transferFrom(msg.sender, address(this), details.price),
            "Token transfer failed"
        );

        if (details.asset == AssetType.BOARD) {
            boardContract.transferFrom(
                details.owner,
                msg.sender,
                details.assetId
            );
        } else if (details.asset == AssetType.PLAYER) {
            playerContract.safeTransferFrom(
                details.owner,
                msg.sender,
                details.assetId,
                details.amount,
                ""
            );

            addressToPlayerListings[details.owner][details.assetId] -= details
                .amount;
        }

        delete idToListingDetails[listingId];
        listings.remove(listingId);
    }
}
