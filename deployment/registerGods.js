const fs = require("fs");
const hardhat = require("hardhat");
const ethers = hardhat.ethers;

async function main() {
    const signer = await ethers.getSigner();

    const godAddress = "0x3fC3D5a080f370aBa851b29E914955E2f2640869";


    const GodFactory = await ethers.getContractFactory("GOD");
    const God = GodFactory.attach(godAddress);

    await God.connect(signer).registerType(1, [true, 0, 1, 1, 1, 4, 2]); // Warrior
    console.log("Warrior");
    await God.connect(signer).registerType(2, [true, 0, 3, 3, 1, 2, 1]); // Archer
    console.log("Archer");
    await God.connect(signer).registerType(3, [true, 0, 2, 2, 2, 2, 3]); // Wizard
    console.log("Wizard");
    await God.connect(signer).registerType(4, [true, 1, 2, 2, 3, 4, 2]); // Healer
    console.log("Healer");
    await God.connect(signer).registerType(5, [true, 0, 1, 1, 4, 5, 3]); // Titan
    console.log("Titan");

    console.log("Done");
}

main().then(() => {
    process.exit(0);
}).catch((e) => {
    console.log(e);
    process.exit(-1);
});