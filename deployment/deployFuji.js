const fs = require("fs");
const hardhat = require("hardhat");
const ethers = hardhat.ethers;

async function main() {
    // const signer = await ethers.getSigner();
    const BoardFactory = await ethers.getContractFactory("BOARD");
    const FlashFactory = await ethers.getContractFactory("FLASH");
    const GodFactory = await ethers.getContractFactory("GOD");
    const MarketplaceFactory = await ethers.getContractFactory("Marketplace");

    const God = await GodFactory.deploy();
    await God.deployed();

    const Board = await BoardFactory.deploy();
    await Board.deployed();

    const Flash = await FlashFactory.deploy();
    await Flash.deployed();

    const Marketplace = await MarketplaceFactory.deploy(
        Board.address,
        Flash.address,
        God.address
    );
    await Marketplace.deployed();

    const addresses = "God: " + God.address + "\n" +
        "Board: " + Board.address + "\n" +
        "Flash: " + Flash.address + "\n" +
        "Marketplace: " + Marketplace.address + "\n";

    console.log(addresses);
    fs.writeFile("./addresses.txt", addresses, () => {
        console.log("Done");
    });
}

main().then(() => {
    process.exit(0);
}).catch((e) => {
    console.log(e);
    process.exit(-1);
});