const fs = require("fs");
const hardhat = require("hardhat");
const ethers = hardhat.ethers;

async function main() {
    const signer = await ethers.getSigner();
    const ArenaFactory = await ethers.getContractFactory("ARENA");
    const SonsFactory = await ethers.getContractFactory("SONS");
    const BiliraFactory = await ethers.getContractFactory("BILIRA");
    const GodFactory = await ethers.getContractFactory("GOD");
    const XPFactory = await ethers.getContractFactory("XP");
    const MatchMakerFactory = await ethers.getContractFactory("MatchMaker");
    const MarketplaceFactory = await ethers.getContractFactory("Marketplace");

    const XP = await XPFactory.deploy();
    await XP.deployed();
    console.log("XP deployed");

    const God = await GodFactory.deploy();
    await God.deployed();
    console.log("God deployed");

    const Arena = await ArenaFactory.deploy();
    await Arena.deployed();
    console.log("Arena deployed");

    const Bilira = await BiliraFactory.deploy();
    await Bilira.deployed();
    console.log("Bilira deployed");

    const Sons = await SonsFactory.deploy();
    await Sons.deployed();
    console.log("Sons deployed");

    const Marketplace = await MarketplaceFactory.deploy(
        Arena.address,
        God.address,
        Sons.address,
        Bilira.address
    );
    await Marketplace.deployed();
    console.log("Marketplace deployed");

    const MatchMaker = await MatchMakerFactory.deploy(
        XP.address,
        Arena.address,
        Sons.address,
        Bilira.address,
        God.address
    );
    await MatchMaker.deployed();
    console.log("MatchMaker deployed");

    const addresses = "{\n\tGod: '" + God.address + "',\n" +
        "Arena: '" + Arena.address + "',\n" +
        "Sons: '" + Sons.address + "',\n" +
        "XP: '" + XP.address + "',\n" +
        "Bilira: '" + Bilira.address + "',\n" +
        "God: '" + God.address + "',\n" +
        "MatchMaker: '" + MatchMaker.address + "',\n" +
        "Marketplace: '" + Marketplace.address + "'\n}";

    const addressesForTS = "{\n\tGodContract: '" + God.address + "',\n" +
        "ArenaContract: '" + Arena.address + "',\n" +
        "SonsContract: '" + Sons.address + "',\n" +
        "XpContract: '" + XP.address + "',\n" +
        "BiliraContract: '" + Bilira.address + "',\n" +
        "MatchMakerContract: '" + MatchMaker.address + "',\n" +
        "MarketplaceContract: '" + Marketplace.address + "'\n}";

    console.log(addresses);
    console.log(addressesForTS);
}

main().then(() => {
    process.exit(0);
}).catch((e) => {
    console.log(e);
    process.exit(-1);
});