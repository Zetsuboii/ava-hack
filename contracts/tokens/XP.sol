// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "@openzeppelin/contracts/access/Ownable.sol";

/**
    Sadece oyun kontratı harcama yapabilir.
    -   Tek seferlik harcama hakkı olacak (bunu seçtim)
    -   Access kontrol yapıp eğer oyun kontratı değilse 
        harcamasına izin vermeyeceğiz
*/
contract XP is Ownable {
    uint256 public totalSupply = 0;

    mapping(address => uint256) public balances;
    mapping(address => bool) boards;

    event XPTransferred(address to, uint256 amount);

    modifier onlyBoard() {
        require(boards[msg.sender], "ONLY_BOARDS");
        _;
    }

    function registerBoard(address boardAddress) external onlyOwner {
        boards[boardAddress] = true;
    }

    function mint(address to, uint256 amount) external onlyBoard {
        totalSupply += amount;
        balances[to] += amount;

        emit XPTransferred(to, amount);
    }
}
