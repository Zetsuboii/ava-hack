// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

enum CardType {
    DAMAGE,
    HEAL
}

struct Card {
    bool initialized;
    CardType cardType;
    uint8 rangeX;
    uint8 rangeY;
    uint8 deployEnergy;
    uint8 health;
    uint8 points;
}

contract GOD is ERC1155, Ownable {
    constructor() ERC1155("") {}

    mapping(uint256 => Card) public idToCardDetails;

    function getCard(uint256 typeId) external view returns (Card memory) {
        require(idToCardDetails[typeId].initialized, "Card doesn't exists");
        return idToCardDetails[typeId];
    }

    function getBalances() external view returns (uint256[] memory) {
        uint256[] memory balances = new uint256[](5);
        for (uint256 i = 0; i < 5; i++) {
            balances[i] = balanceOf(msg.sender, i + 1);
        }

        return balances;
    }

    function registerType(uint256 cardType, Card calldata details)
        external
        onlyOwner
    {
        idToCardDetails[cardType] = details;
    }

    function setURI(string memory newuri) public onlyOwner {
        _setURI(newuri);
    }

    function mint(
        address account,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public onlyOwner {
        _mint(account, id, amount, data);
    }

    function mintBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public onlyOwner {
        _mintBatch(to, ids, amounts, data);
    }
}
