const hardhat = require("hardhat");
const ethers = hardhat.ethers;

const ADDR = require("./addresses");

async function main() {
    const signer = await ethers.getSigner();
    const GodFactory = await ethers.getContractFactory("GOD");
    const MarketplaceFactory = await ethers.getContractFactory("Marketplace");

    const God = GodFactory.attach(ADDR.God);
    const Marketplace = MarketplaceFactory.attach(ADDR.Marketplace);


}

main().then(() => {
    process.exit(0);
}).catch((e) => {
    console.log(e);
    process.exit(-1);
});