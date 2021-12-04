// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

struct ArenaDetails {
    uint8 gameConstant;
    uint16 winnerPercent;
    uint16 ownerPercent;
    uint256 entranceFee;
}

contract ARENA is ERC721, Ownable {
    mapping(uint256 => ArenaDetails) public idToArenaDetails;

    event ArenaMinted(address to, uint256 tokenId);

    constructor() ERC721("ARENA", "ARN") {}

    function mint(
        address to,
        uint256 tokenId,
        ArenaDetails calldata details
    ) external onlyOwner {
        idToArenaDetails[tokenId] = details;
        _mint(to, tokenId);

        emit ArenaMinted(to, tokenId);
    }
}
