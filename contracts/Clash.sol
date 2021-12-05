// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

// Tokens
import "./tokens/GOD.sol";
import "./tokens/ARENA.sol";
import "./tokens/SONS.sol";
import "./tokens/XP.sol";

enum MoveType {
    PUT_CARD,
    MOVE,
    ATTACK,
    ATTACK_BASE,
    ATTACK_GOD,
    HEAL,
    HEAL_GOD
}

enum Turn {
    PLAYER_ONE,
    PLAYER_TWO
}

struct Cell {
    bool occupied;
    uint8 slotId;
    uint8 health;
    uint8 cardId;
    address owner;
}

struct Player {
    uint8 health;
    uint8 energy;
    address addr;
    uint8[] deck;
}

struct Origin {
    uint8 row;
    uint8 col;
}

struct Target {
    uint8 row;
    uint8 col;
}

struct Move {
    MoveType moveType;
    uint8 slotId;
    Origin origin;
    Target target;
}

contract Clash {
    uint8 constant MOVE_ENERGY_COST = 1;
    uint8 constant ATTACK_ENERGY_COST = 1;
    uint8 constant HEAL_ENERGY_COST = 1;
    uint8 constant WINNER_XP = 10;
    uint8 constant LOSER_XP = 2;
    uint8 constant GOD_MULTIPLIER = 3;

    // Game config
    Turn private _turn = Turn.PLAYER_ONE;
    uint8 private immutable _tableSize;
    uint8 private immutable _energyPerRound;
    // Percentages
    uint16 private immutable _winnerPercent;
    uint16 private immutable _boardOwnerPercent;
    uint16 private _gameTick = 0;
    address private immutable _boardOwner;
    address private immutable _owner;
    address private _currentPlayer;

    XP xpContract;
    SONS tokenContract;
    GOD godContract;

    Player playerOne;
    Player playerTwo;
    Player currentPlayer;

    /* function getAllCells() external view returns (Cell[] memory) {
        Cell[] memory cellArray = new Cell[](_tableSize * _tableSize);
        for (uint256 i = 0; i < cellArray.length; i++) {
            cellArray[i] = gameBoard[i / 5][i % 5];
        }
        return cellArray;
    }
 */
    function getCell(uint8 i, uint8 j) external view returns (Cell memory) {
        return gameBoard[i][j];
    }

    function getEnemyDeck() external view returns (uint8[] memory) {
        return msg.sender == playerOne.addr ? playerTwo.deck : playerOne.deck;
    }

    // Player => cardIdx => lastGameTick
    mapping(address => mapping(uint8 => uint16)) lastGameTicks;
    mapping(address => uint256) public flashLoans;

    Cell[][] public gameBoard;

    event PutCard(uint8 col, uint8 typeId);
    event MoveCard(uint8 orow, uint8 ocol, uint8 trow, uint8 tcol);
    event AttackCard(
        uint8 orow,
        uint8 ocol,
        uint8 trow,
        uint8 tcol,
        uint8 points
    );
    event AttackBase(uint8 orow, uint8 ocol, uint8 damage);
    event AttackGodPower(uint8 trow, uint8 tcol, uint8 points);
    event HealCard(
        uint8 orow,
        uint8 ocol,
        uint8 trow,
        uint8 tcol,
        uint8 points
    );
    event HealGodPower(uint8 trow, uint8 tcol, uint8 points);
    event TurnFinished(uint8 turn);
    event GameFinished(address winner);

    modifier rightTurn() {
        require(msg.sender == currentPlayer.addr, "Not right turn");
        _;
    }

    constructor(
        XP xpAddress,
        SONS sonsAddress,
        GOD godAddress,
        ArenaDetails memory arena,
        address arenaOwner,
        address addressOne,
        address addressTwo,
        uint8[] memory deckOne,
        uint8[] memory deckTwo
    ) {
        require(
            deckOne.length == arena.gameConstant * 2 - 1 &&
                deckTwo.length == arena.gameConstant * 2 - 1,
            "Deck size doesn't match game requirements"
        );

        xpContract = XP(xpAddress);
        tokenContract = SONS(sonsAddress);
        godContract = GOD(godAddress);

        playerOne = Player({
            health: _baseHealth(xpContract.balances(addressOne)),
            energy: arena.gameConstant,
            addr: addressOne,
            deck: deckOne
        });

        playerTwo = Player({
            health: _baseHealth(xpContract.balances(addressTwo)),
            energy: arena.gameConstant,
            addr: addressTwo,
            deck: deckTwo
        });

        currentPlayer = playerTwo;

        // Set immutables
        _owner = msg.sender;
        _boardOwner = arenaOwner;
        _boardOwnerPercent = arena.ownerPercent;
        _winnerPercent = arena.winnerPercent;
        _energyPerRound = arena.gameConstant;
        _tableSize = arena.gameConstant * 2 - 1;
    }

    function playTurn(Move[] calldata moves) external rightTurn {
        for (uint256 i = 0; i < moves.length; i++) {
            _playMove(moves[i]);
        }
        _endTurn();
    }

    function _playMove(Move calldata move) private {
        /* 
            PUT_CARD,
            MOVE,
            ATTACK,
            ATTACK_BASE,
            ATTACK_GOD,
            HEAL,
            HEAL_GOD 
        */
        if (move.moveType == MoveType.PUT_CARD)
            _putCardOnBoard(move.slotId, move.origin.col);
        else if (move.moveType == MoveType.MOVE)
            _moveCardToCell(move.origin, move.target);
        else if (move.moveType == MoveType.ATTACK)
            _attackCell(move.origin, move.target);
        else if (move.moveType == MoveType.ATTACK_BASE)
            _attackBase(move.origin);
        else if (move.moveType == MoveType.ATTACK_GOD)
            _attackGodPower(move.slotId, move.target);
        else if (move.moveType == MoveType.HEAL)
            _healCell(move.origin, move.target);
        else if (move.moveType == MoveType.HEAL_GOD)
            _healGodPower(move.slotId, move.target);
    }

    // ######### PUT CARD ######### //

    function _putCardOnBoard(uint8 slotId, uint8 col) private {
        require(
            _gameTick - lastGameTicks[currentPlayer.addr][slotId] >= 2,
            "Can't put player this turn"
        );
        require(col < _tableSize, "Invalid column");
        require(!gameBoard[0][col].occupied, "Cell is occupied");

        uint8 typeId = currentPlayer.deck[slotId];
        Card memory card = godContract.getCard(typeId);
        require(
            currentPlayer.energy > card.deployEnergy,
            "Energy not sufficent"
        );

        currentPlayer.energy -= card.deployEnergy;

        gameBoard[0][col] = Cell({
            occupied: true,
            slotId: slotId,
            health: card.health,
            cardId: typeId,
            owner: currentPlayer.addr
        });

        emit PutCard(col, typeId);
    }

    // ######### MOVE CARD ######### //

    function _moveCardToCell(Origin calldata origin, Target calldata target)
        private
    {
        Cell memory originCell = gameBoard[origin.row][origin.col];

        // Upwards orientation
        bool upwards = currentPlayer.addr == playerOne.addr;

        require(
            target.row < _tableSize && target.col < _tableSize,
            "Target off-bounds"
        );
        require(originCell.owner == msg.sender, "Not owning the origin");
        require(currentPlayer.energy > MOVE_ENERGY_COST, "Energy insufficient");

        uint8 vertDistance = upwards
            ? target.row - origin.row
            : origin.row - target.row;
        uint8 horizDistance = target.col >= origin.col
            ? target.col - origin.col
            : origin.col - target.col;

        require(vertDistance == 1 || horizDistance == 1, "Illegal movement");

        currentPlayer.energy -= MOVE_ENERGY_COST;

        gameBoard[target.row][target.col] = originCell;
        delete gameBoard[origin.row][origin.col];

        emit MoveCard(origin.row, origin.col, target.row, target.col);
    }

    // ######### MOVE CARD ######### //

    function _attackCell(Origin calldata origin, Target calldata target)
        private
    {
        Cell memory originCell = gameBoard[origin.row][origin.col];
        Cell memory targetCell = gameBoard[target.row][target.col];

        require(originCell.owner == msg.sender, "Not owning the pawn");
        require(targetCell.occupied, "Attacking on an empty cell");
        require(targetCell.owner != msg.sender, "Attacking on own cells");

        Card memory card = godContract.getCard(originCell.cardId);
        require(card.cardType == CardType.DAMAGE, "Not a card attack");

        // Upwards orientation
        bool upwards = currentPlayer.addr == playerOne.addr;

        uint8 vertDistance = upwards
            ? target.row - origin.row
            : origin.row - target.row;
        uint8 horizDistance = target.col >= origin.col
            ? target.col - origin.col
            : origin.col - target.col;

        require(
            vertDistance <= card.rangeY && horizDistance <= card.rangeX,
            "Target is out of range"
        );
        require(
            currentPlayer.energy > ATTACK_ENERGY_COST,
            "Not enough energy for attack"
        );

        currentPlayer.energy -= ATTACK_ENERGY_COST;

        if (targetCell.health <= card.points) {
            // This means the target is killed
            lastGameTicks[targetCell.owner][targetCell.slotId] = _gameTick;
            delete gameBoard[target.row][target.col];
        } else {
            // Only reflect the damage
            gameBoard[target.row][target.col].health -= card.points;
        }

        emit AttackCard(
            origin.row,
            origin.col,
            target.row,
            target.col,
            card.points
        );
    }

    function _attackBase(Origin calldata origin) private {
        Player storage targetPlayer = _turn == Turn.PLAYER_ONE
            ? playerTwo
            : playerOne;

        Cell memory originCell = gameBoard[origin.row][origin.col];
        Card memory card = godContract.getCard(originCell.cardId);

        require(originCell.owner == msg.sender, "Not owning the pawn");
        require(card.cardType == CardType.DAMAGE, "Not an attack player");
        require(currentPlayer.energy > ATTACK_ENERGY_COST, "Not enough energy");

        // Upwards orientation
        bool upwards = currentPlayer.addr == playerOne.addr;

        require(
            upwards
                ? (origin.row + card.rangeY >= _tableSize)
                : (origin.row < card.rangeY),
            "Base is out of range"
        );

        currentPlayer.energy -= ATTACK_ENERGY_COST;

        if (card.points > targetPlayer.health) {
            // This means game is over
            _finishGame(currentPlayer.addr, targetPlayer.addr);
        } else {
            targetPlayer.health -= card.points;
        }

        emit AttackBase(origin.row, origin.col, card.points);
    }

    function _attackGodPower(uint8 slotId, Target calldata target) private {
        Player storage targetPlayer = _turn == Turn.PLAYER_ONE
            ? playerTwo
            : playerOne;

        Cell memory targetCell = gameBoard[target.row][target.col];
        Card memory card = godContract.getCard(currentPlayer.deck[slotId]);

        uint256 pool = (tokenContract.allowance(_owner, address(this)) *
            _winnerPercent) / 1000;

        require(targetCell.occupied, "Target cell is empty");
        require(targetCell.owner == targetPlayer.addr, "Wrong target player");
        require(
            flashLoans[msg.sender] <= pool,
            "No balance left to use god power"
        );

        flashLoans[msg.sender] += (pool / 5);

        if (targetCell.health <= card.points) {
            // Target card is dead
            lastGameTicks[targetPlayer.addr][targetCell.slotId] = _gameTick;
            delete gameBoard[target.row][target.col];
        } else {
            gameBoard[target.row][target.col].health -=
                card.points *
                GOD_MULTIPLIER;
        }

        emit AttackGodPower(
            target.row,
            target.col,
            card.points * GOD_MULTIPLIER
        );
    }

    // ######### HEAL ######### //

    function _healCell(Origin calldata origin, Target calldata target) private {
        Cell memory originCell = gameBoard[origin.row][origin.col];
        Cell memory targetCell = gameBoard[target.row][target.col];
        Card memory card = godContract.getCard(originCell.cardId);

        require(originCell.owner == msg.sender, "Not owning the pawn");
        require(targetCell.occupied, "Target cell is empty");
        require(targetCell.owner == msg.sender, "Not owning the target");
        require(card.cardType == CardType.HEAL, "Not a heal card");

        // Upwards orientation
        bool upwards = currentPlayer.addr == playerOne.addr;

        uint8 vertDistance = upwards
            ? target.row - origin.row
            : origin.row - target.row;
        uint8 horizDistance = target.col >= origin.col
            ? target.col - origin.col
            : origin.col - target.col;

        require(
            vertDistance <= card.rangeY && horizDistance <= card.rangeX,
            "Target is out of range"
        );
        require(currentPlayer.energy > HEAL_ENERGY_COST, "Not enough energy");

        currentPlayer.energy -= HEAL_ENERGY_COST;

        gameBoard[target.row][target.col].health += card.points;

        emit HealCard(
            origin.row,
            origin.col,
            target.row,
            target.col,
            card.points
        );
    }

    function _healGodPower(uint8 slotId, Target calldata target) private {
        Cell memory targetCell = gameBoard[target.row][target.col];
        Card memory card = godContract.getCard(currentPlayer.deck[slotId]);

        uint256 pool = (tokenContract.allowance(_owner, address(this)) *
            _winnerPercent) / 1000;

        require(
            flashLoans[msg.sender] <= pool,
            "No balance left to use god power"
        );
        require(card.cardType == CardType.HEAL, "Not a heal card");
        require(targetCell.occupied, "Target cell is empty");
        require(targetCell.owner == msg.sender, "Not owning the target");

        flashLoans[msg.sender] += (pool / 5);

        gameBoard[target.row][target.col].health +=
            card.points *
            GOD_MULTIPLIER;

        emit HealGodPower(target.row, target.col, card.points * GOD_MULTIPLIER);
    }

    // ######### EVALUATION HELPERS ######### //

    function _endTurn() private {
        currentPlayer.energy += _energyPerRound;
        _turn = (_turn == Turn.PLAYER_ONE) ? Turn.PLAYER_TWO : Turn.PLAYER_ONE;
        currentPlayer = (_turn == Turn.PLAYER_ONE) ? playerTwo : playerOne;
        _gameTick++;

        emit TurnFinished(uint8(_turn));
    }

    function _finishGame(address winner, address loser) private {
        uint256 allowance = tokenContract.allowance(_owner, address(this));

        // Winner payment
        require(
            tokenContract.transferFrom(
                _owner,
                winner,
                (allowance * _winnerPercent) / 1000 - flashLoans[winner]
            ),
            "Winner payment failed"
        );

        // Board owner payment
        require(
            tokenContract.transferFrom(
                _owner,
                _boardOwner,
                (allowance * _boardOwnerPercent) / 1000
            ),
            "Arena owner payment failed"
        );

        xpContract.mint(winner, WINNER_XP);
        xpContract.mint(loser, LOSER_XP);

        emit GameFinished(winner);
    }

    // ######### CALCULATION HELPERS ######### //

    function _baseHealth(uint256 xp) private pure returns (uint8) {
        if (xp < 100) return 10;
        if (xp < 450) return 15;
        if (xp < 1050) return 20;
        if (xp < 4350) return 25;
        return 30; // 4350+
    }

    // TODO: Timeout functions
}
