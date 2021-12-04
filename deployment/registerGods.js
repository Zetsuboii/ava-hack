const fs = require("fs");
const hardhat = require("hardhat");
const ethers = hardhat.ethers;

async function main() {
    const signer = await ethers.getSigner();

    const godAddress = "0xb6F5e4847F129eA655c25D08D9395f45Dae8Df0E";


    const GodFactory = await ethers.getContractFactory("GOD");
    const God = GodFactory.attach(godAddress);

    await God.connect(signer).registerType(1, [true, 0, 1, 1, 1, 4, 2]); // Warrior
    await God.connect(signer).registerType(2, [true, 0, 3, 3, 1, 2, 1]); // Archer
    await God.connect(signer).registerType(3, [true, 0, 2, 2, 2, 2, 3]); // Wizard
    await God.connect(signer).registerType(4, [true, 1, 2, 2, 3, 4, 2]); // Healer
    await God.connect(signer).registerType(5, [true, 0, 1, 1, 4, 5, 3]); // Titan

    console.log("Done");
}

main().then(() => {
    process.exit(0);
}).catch((e) => {
    console.log(e);
    process.exit(-1);
});