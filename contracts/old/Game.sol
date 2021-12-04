/* // SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "./tokens/BOARD.sol";
import "./tokens/FLASH.sol";
import "./tokens/XP.sol";

struct Cell {
    bool occupied;
    uint8 cardIdx;
    uint8 health;
    uint8 cardType;
    address owner;
}

struct CardT {
    uint8 rangeX;
    uint8 rangeY;
    uint8 energyCost;
    uint8 health;
    uint8 healFactor;
    uint8 damageFactor;
}

struct Player {
    uint8 health;
    uint16 energy;
    address addr;
    uint8[] deck;
}

struct BaseAttackDetails {
    uint8 originRow;
    uint8 originCol;
}

struct TargetDetails {
    uint8 row;
    uint8 col;
}

struct MoveDetails {
    uint8 originRow;
    uint8 originCol;
    uint8 targetRow;
    uint8 targetCol;
}

contract Game {
    uint8 constant MOVE_ENERGY_COST = 1;
    uint8 constant ATTACK_ENERGY_COST = 1;
    uint8 constant HEAL_ENERGY_COST = 1;
    uint8 constant XP_WINNER = 10;
    uint8 constant XP_LOSER = 2;
    uint8 constant GOD_MULTIPLIER = 3;

    uint8 private immutable _size;
    uint8 private immutable _energyPerRound;
    uint16 private immutable _winnerPercent;
    uint16 private immutable _boardOwnerPercent;
    address private immutable _boardOwner;
    address private immutable _owner;
    uint256 pool;

    XP _xpContract;
    FLASH _tokenContract;

    uint16 private gameTick = 0;

    uint8 public turn; // 0 for player one, 1 for player two
    Player pOne;
    Player pTwo;

    // Player => cardIdx => lastGameTick
    mapping(address => mapping(uint8 => uint16)) lastGameTicks;
    mapping(uint8 => CardT) public cardTypes;
    mapping(address => uint256) public addressToFlashLoans;

    Cell[][] public gameBoard;

    modifier rightTurn() {
        require(
            msg.sender == (turn == 0 ? pOne.addr : pTwo.addr),
            "NOT_RIGHT_TURN"
        );
        _;
    }

    constructor(
        address boardOwner,
        BoardDetails memory boardDetails,
        XP xpAddress,
        FLASH flashAddress,
        address addrOne,
        address addrTwo,
        uint8[] memory deckOne,
        uint8[] memory deckTwo
    ) {
        require(
            deckOne.length == boardDetails.gameConstant * 2 &&
                deckTwo.length == boardDetails.gameConstant * 2
        );

        _xpContract = XP(xpAddress);
        _tokenContract = FLASH(flashAddress);

        // TODO: Check if all cards are owned

        pOne = Player({
            health: _calculateBaseHealth(_xpContract.balances(addrOne)),
            energy: boardDetails.gameConstant,
            addr: addrOne,
            deck: deckOne
        });

        pTwo = Player({
            health: _calculateBaseHealth(_xpContract.balances(addrTwo)),
            energy: boardDetails.gameConstant,
            addr: addrTwo,
            deck: deckTwo
        });

        _owner = msg.sender;
        _boardOwner = boardOwner;
        _boardOwnerPercent = boardDetails.ownerPercent;
        _winnerPercent = boardDetails.winnerPercent;
        _energyPerRound = boardDetails.gameConstant;
        _size = boardDetails.gameConstant * 2 - 1;
    }

    function _calculateBaseHealth(uint256 xp) private pure returns (uint8) {
        if (xp < 100) return 10;
        if (xp < 450) return 15;
        if (xp < 1050) return 20;
        if (xp < 4350) return 25;
        return 30; // 4350+
    }

    function putCardToBoard(uint8 cardIdx, uint8 col) external rightTurn {
        Player storage crntPlayer = turn == 0 ? pOne : pTwo;
        uint8 typeId = crntPlayer.deck[cardIdx];

        require(
            gameTick - lastGameTicks[crntPlayer.addr][cardIdx] >= 2,
            "CardT cooldownda"
        );
        require(col < _size, "Column boardun disina cikiyor");
        require(!gameBoard[0][col].occupied, "Cell dolu");
        require(
            crntPlayer.energy > cardTypes[typeId].energyCost,
            "NOT_ENOUGH_ENERGY"
        );

        // Enerji azalt
        crntPlayer.energy -= cardTypes[typeId].energyCost;

        gameBoard[0][col] = Cell({
            cardIdx: cardIdx,
            occupied: true,
            health: cardTypes[cardIdx].health,
            cardType: crntPlayer.deck[cardIdx],
            owner: crntPlayer.addr
        });
    }

    function moveCardToCell(MoveDetails calldata move) external rightTurn {
        Player storage crntPlayer = turn == 0 ? pOne : pTwo;
        Cell memory crntCell = gameBoard[move.originRow][move.originCol];

        require(move.targetRow < _size && move.targetCol < _size);

        require(crntCell.owner == msg.sender);
        require(!gameBoard[move.targetRow][move.targetCol].occupied);
        require(crntPlayer.energy > MOVE_ENERGY_COST);
        require(
            move.targetRow > move.originRow || move.targetCol > move.originCol
        );
        require(
            move.originRow == move.targetRow || move.originCol == move.targetCol
        );
        require(
            move.targetCol - move.originCol <= 1 &&
                move.targetRow - move.originRow <= 1
        );

        // Enerji azalt
        crntPlayer.energy -= MOVE_ENERGY_COST;

        gameBoard[move.targetRow][move.targetCol] = crntCell;
        delete gameBoard[move.originRow][move.originCol];

        // TODO: Emit an event
    }

    function attackCell(MoveDetails calldata move) external rightTurn {
        Player storage crntPlayer = turn == 0 ? pOne : pTwo;
        Cell memory crntCell = gameBoard[move.originRow][move.originCol];
        Cell memory targetCell = gameBoard[move.targetRow][move.targetCol];
        CardT memory crntCard = cardTypes[crntCell.cardType];

        require(crntCard.damageFactor > 0, "NOT_ATTACK_CARD");
        require(targetCell.occupied, "ATTACK_ON_EMPTY_CELL");
        require(targetCell.owner != msg.sender, "ATTACK_ON_OWN_CELL");
        require(crntCell.owner == msg.sender, "NOT_OWNING_PAWN");
        require(
            move.targetCol - move.originCol <= crntCard.rangeX &&
                move.targetRow - move.originRow <= crntCard.rangeY,
            "TARGET_OUT_OF_RANGE"
        );
        require(crntPlayer.energy > ATTACK_ENERGY_COST, "NOT_ENOUGH_ENERGY");

        // Enerji azalt
        crntPlayer.energy -= ATTACK_ENERGY_COST;

        if (targetCell.health <= crntCard.damageFactor) {
            // Kart öldü
            lastGameTicks[msg.sender][targetCell.cardIdx] = gameTick;
            delete gameBoard[move.targetRow][move.targetCol];
        } else {
            gameBoard[move.targetRow][move.targetCol].health -= crntCard
                .damageFactor;
        }

        // TODO: Emit event
    }

    function attackBase(BaseAttackDetails calldata move) external rightTurn {
        // Range kontrolü yap karşı takımın base canını azalt eğer 0sa oyunu biter
        Player storage crntPlayer = turn == 0 ? pOne : pTwo;
        Player storage targetPlayer = turn == 0 ? pTwo : pOne;
        Cell memory crntCell = gameBoard[move.originRow][move.originCol];
        CardT memory crntCard = cardTypes[crntCell.cardType];

        require(crntCard.damageFactor > 0, "NOT_ATTACK_PLAYER");
        require(crntPlayer.energy > HEAL_ENERGY_COST, "NOT_ENOUGH_ENERGY");
        require(crntCell.owner == msg.sender, "NOT_OWNING_PAWN");
        require(move.originRow + crntCard.rangeY >= _size, "NOT_REACHING_BASE");

        // Enerji azalt
        crntPlayer.energy -= ATTACK_ENERGY_COST;
        // Hasar ver
        if (crntCard.damageFactor > targetPlayer.health) {
            // Oyuncu öldü
            _finishGame(crntPlayer.addr, targetPlayer.addr);
        } else {
            targetPlayer.health -= crntCard.damageFactor;
        }

        // TODO: Emit event
    }

    function healCell(MoveDetails calldata move) external rightTurn {
        Player storage crntPlayer = turn == 0 ? pOne : pTwo;
        Cell memory crntCell = gameBoard[move.originRow][move.originCol];
        Cell memory targetCell = gameBoard[move.targetRow][move.targetCol];
        CardT memory crntCard = cardTypes[crntCell.cardType];

        require(crntCard.healFactor > 0, "NOT_HEAL_CARD");
        require(targetCell.occupied, "HEAL_ON_EMPTY_CELL");
        require(targetCell.owner == msg.sender, "HEAL_ONE_ENEMY_CELL");
        require(crntCell.owner == msg.sender, "NOT_OWNING_PAWN");
        require(
            move.targetCol - move.originCol <= crntCard.rangeX &&
                move.targetRow - move.originRow <= crntCard.rangeY,
            "TARGET_OUT_OF_RANGE"
        );
        require(crntPlayer.energy > HEAL_ENERGY_COST, "NOT_ENOUGH_ENERGY");

        // Enerji azalt
        crntPlayer.energy -= HEAL_ENERGY_COST;

        gameBoard[move.targetRow][move.targetCol].health += crntCard.healFactor;

        // TODO: Emit event
    }

    function endTurn() external rightTurn {
        Player storage crntPlayer = turn == 0 ? pOne : pTwo;
        crntPlayer.energy += _energyPerRound;
        turn = turn ^ 1;
        gameTick++;

        // TODO: emit Event
    }

    function attackGodPower(uint8 cardIdx, TargetDetails calldata target)
        external
        rightTurn
    {
        Player memory crntPlayer = turn == 0 ? pOne : pTwo;
        Player memory enemyPlayer = turn == 0 ? pTwo : pOne;
        Cell memory targetCell = gameBoard[target.row][target.col];
        CardT memory selectedCard = cardTypes[crntPlayer.deck[cardIdx]];

        uint256 allowance = _tokenContract.allowance(_owner, address(this));

        pool = pool == 0 ? (allowance * _winnerPercent) / 1000 : pool;

        require(
            addressToFlashLoans[msg.sender] <= pool,
            "No balance left to use god power"
        );

        require(targetCell.occupied, "Target cell is empty");
        require(targetCell.owner == enemyPlayer.addr, "Wrong target player");

        // TODO: Implement dynamic flash loan
        addressToFlashLoans[msg.sender] += pool / 5;

        if (targetCell.health <= selectedCard.damageFactor) {
            // Kart öldü
            lastGameTicks[enemyPlayer.addr][targetCell.cardIdx] = gameTick;
            delete gameBoard[target.row][target.col];
        } else {
            gameBoard[target.row][target.col].health -= selectedCard
                .damageFactor;
        }
    }

    function healGodPower(uint8 cardIdx, TargetDetails calldata target)
        external
        rightTurn
    {
        Player memory crntPlayer = turn == 0 ? pOne : pTwo;
        Cell memory targetCell = gameBoard[target.row][target.col];
        CardT memory selectedCard = cardTypes[crntPlayer.deck[cardIdx]];

        uint256 allowance = _tokenContract.allowance(_owner, address(this));

        pool = pool == 0 ? (allowance * _winnerPercent) / 1000 : pool;
        require(
            addressToFlashLoans[msg.sender] <= pool,
            "No balance left to use god power"
        );
        require(selectedCard.healFactor > 0, "Not a heal card");
        require(targetCell.occupied, "Target cell is empty");
        require(targetCell.owner == msg.sender, "Wrong target player");

        // TODO: Implement dynamic flash loan
        addressToFlashLoans[msg.sender] += pool / 5;

        gameBoard[target.row][target.col].health += selectedCard.healFactor;
    }

    function _finishGame(address winner, address loser) private {
        uint256 allowance = _tokenContract.allowance(_owner, address(this));
        // Transfer winner payment to the winner
        _tokenContract.transferFrom(
            _owner,
            winner,
            (allowance * _winnerPercent) / 1000
        );
        // Transfer board payment to the board owner
        _tokenContract.transferFrom(
            _owner,
            _boardOwner,
            (allowance * _boardOwnerPercent) / 1000
        );

        _xpContract.mint(winner, XP_WINNER);
        _xpContract.mint(loser, XP_LOSER);

        // TODO: emit event
    }
}
 */