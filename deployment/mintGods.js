const fs = require("fs");
const hardhat = require("hardhat");
const ethers = hardhat.ethers;

const ADDR = require("./addresses");

async function main() {
    const signer = await ethers.getSigner();

    const addr1 = "0x462E91b89082C7F465D9ffAec3559CAe38c056F3";
    const addr2 = "0xd0c3386D693A303f66cE76C79CD1549DFB5F1e0D";

    const GodFactory = await ethers.getContractFactory("GOD");
    const God = GodFactory.attach(ADDR.God);

    await God.connect(signer).mintBatch(addr1, [1, 2, 3, 4, 5], [5, 5, 5, 5, 5], ethers.utils.toUtf8Bytes(""));
    await God.connect(signer).mintBatch(addr2, [1, 2, 3, 4, 5], [5, 5, 5, 5, 5], ethers.utils.toUtf8Bytes(""));
    await God.connect(signer).mintBatch(signer.address, [1, 2, 3, 4, 5], [5, 5, 5, 5, 5], ethers.utils.toUtf8Bytes(""));

    console.log("Done");
}

main().then(() => {
    process.exit(0);
}).catch((e) => {
    console.log(e);
    process.exit(-1);
});