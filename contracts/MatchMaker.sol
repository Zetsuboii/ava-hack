// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "@openzeppelin/contracts/access/Ownable.sol";

import "./Clash.sol";
// tokens
import "./tokens/BILIRA.sol";
import "./tokens/ARENA.sol";
import "./tokens/SONS.sol";
import "./tokens/GOD.sol";
import "./tokens/XP.sol";

struct WaitingPlayer {
    bool exists;
    address addr;
    uint256 gameId;
    uint8[] deck;
}

struct Instance {
    address addr;
    uint256 gameId;
}

contract MatchMaker is Ownable {
    XP xpContract;
    ARENA arenaContract;
    SONS snsContract;
    GOD godContract;
    BILIRA biliraContract;

    uint256 gameNonce = 0;

    mapping(uint256 => WaitingPlayer) public arenaToPlayer;
    mapping(address => bool) public inGame;

    event GameStarted(uint256 gameId, address instance);
    event GameRegistered(uint256 gameId);
    event WaitingLeave(uint256 gameId, address leavingPlayer);

    constructor(
        XP xpAddress,
        ARENA arenaAddress,
        SONS sonsAddress,
        BILIRA biliraAddress,
        GOD playerAddress
    ) {
        xpContract = XP(xpAddress);
        arenaContract = ARENA(arenaAddress);
        snsContract = SONS(sonsAddress);
        godContract = GOD(playerAddress);
        biliraContract = BILIRA(biliraAddress);
    }

    function registerToMatch(uint256 arenaId, uint8[] calldata deck) external {
        address boardOwner = arenaContract.ownerOf(arenaId);

        require(boardOwner != address(0), "Board isn't owned by anyone");
        // require(!inGame[msg.sender], "Player is already in game");

        WaitingPlayer memory waitingPlayer = arenaToPlayer[arenaId];
        (
            uint8 gameConstant,
            uint16 winnerPercent,
            uint16 ownerPercent,
            uint256 entranceFee
        ) = arenaContract.idToArenaDetails(arenaId);

        require(
            deck.length == gameConstant * 2 - 1,
            "Deck is not the right size"
        );

        require(
            snsContract.transferFrom(msg.sender, address(this), entranceFee),
            "Fee payment failed"
        );

        if (waitingPlayer.exists) {
            // Last player to join starts first
            Clash instance = new Clash({
                arenaOwner: boardOwner,
                arena: ArenaDetails(
                    gameConstant,
                    winnerPercent,
                    ownerPercent,
                    entranceFee
                ),
                xpAddress: xpContract,
                sonsAddress: snsContract,
                godAddress: godContract,
                addressOne: msg.sender,
                addressTwo: waitingPlayer.addr,
                deckOne: deck,
                deckTwo: waitingPlayer.deck
            });

            require(
                snsContract.approve(address(instance), 2 * entranceFee),
                "Game token approve failed"
            );

            emit GameStarted(waitingPlayer.gameId, address(instance));

            delete inGame[msg.sender];
            delete inGame[waitingPlayer.addr];
            delete arenaToPlayer[arenaId];
            return;
        }

        arenaToPlayer[arenaId] = WaitingPlayer({
            exists: true,
            gameId: gameNonce++,
            addr: msg.sender,
            deck: deck
        });

        inGame[msg.sender] = true;

        emit GameRegistered(gameNonce);
    }

    function leaveGame(uint256 arenaId) external {
        /* require(
            arenaToPlayer[arenaId].addr == msg.sender,
            "Address is not the waiting player"
        ); */

        (, , , uint256 entranceFee) = arenaContract.idToArenaDetails(arenaId);
        require(
            snsContract.approve(msg.sender, entranceFee),
            "Entrance fee approve failed"
        );

        delete inGame[msg.sender];
        delete arenaToPlayer[arenaId];

        emit WaitingLeave(arenaId, msg.sender);
    }
}
