// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "@openzeppelin/contracts/access/Ownable.sol";

import "./Game.sol";
// tokens
import "./tokens/BOARD.sol";
import "./tokens/FLASH.sol";
import "./tokens/GOD.sol";
import "./tokens/XP.sol";

struct WaitingPlayer {
    bool exists;
    address addr;
    uint256 gameId;
    uint8[] deck;
}

contract MatchMaker is Ownable {
    XP xpContract;
    BOARD boardContract;
    FLASH tokenContract;
    GOD playerContract;

    uint256 gameNonce = 0;

    mapping(uint256 => WaitingPlayer) public boardToPlayer;
    mapping(address => bool) public inGame;

    event GameStarted(uint256 gameId);
    event GameRegistered(uint256 gameId);

    constructor(
        XP xpAddress,
        BOARD boardAddress,
        FLASH tokenAddress,
        GOD playerAddress
    ) {
        xpContract = XP(xpAddress);
        boardContract = BOARD(boardAddress);
        tokenContract = FLASH(tokenAddress);
        playerContract = GOD(playerAddress);
    }

    function registerToMatch(uint256 boardId, uint8[] calldata deck) external {
        address boardOwner = boardContract.ownerOf(boardId);

        require(boardOwner == address(0), "Board isn't owned by anyone");
        require(!inGame[msg.sender], "Player is already in game");

        WaitingPlayer memory waitingPlayer = boardToPlayer[boardId];
        (
            uint8 gameConstant,
            uint16 winnerPercent,
            uint16 ownerPercent,
            uint256 entranceFee
        ) = boardContract.idToBoardDetails(boardId);

        require(
            deck.length == gameConstant * 2 - 1,
            "Deck is not the right size"
        );

        require(
            tokenContract.transferFrom(msg.sender, address(this), entranceFee),
            "Fee payment failed"
        );

        if (waitingPlayer.exists) {
            Game instance = new Game({
                boardOwner: boardOwner,
                boardDetails: BoardDetails(
                    gameConstant,
                    winnerPercent,
                    ownerPercent,
                    entranceFee
                ),
                xpAddress: xpContract,
                flashAddress: tokenContract,
                addrOne: waitingPlayer.addr,
                addrTwo: msg.sender,
                deckOne: waitingPlayer.deck,
                deckTwo: deck
            });

            require(
                tokenContract.approve(address(instance), 2 * entranceFee),
                "Game token approve failed"
            );

            emit GameStarted(waitingPlayer.gameId);
            delete boardToPlayer[boardId];
            return;
        }

        boardToPlayer[boardId] = WaitingPlayer({
            exists: true,
            gameId: gameNonce++,
            addr: msg.sender,
            deck: deck
        });

        emit GameRegistered(gameNonce);
    }

    // TODO: Leave Game
}
