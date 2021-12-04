const fs = require("fs");
const hardhat = require("hardhat");
const ethers = hardhat.ethers;

async function main() {
    const signer = await ethers.getSigner();

    const godAddress = "0x3fC3D5a080f370aBa851b29E914955E2f2640869";
    const addr1 = "0x1070cF71bEFe2D83faE5CfD337f5A118F61F227f";
    const addr2 = "0xd0c3386D693A303f66cE76C79CD1549DFB5F1e0D";

    const GodFactory = await ethers.getContractFactory("GOD");
    const God = GodFactory.attach(godAddress);

    await God.connect(signer).mintBatch(addr1, [1, 2, 3, 4, 5], [100, 100, 100, 100, 100], ethers.utils.toUtf8Bytes(""));
    await God.connect(signer).mintBatch(addr2, [1, 2, 3, 4, 5], [100, 100, 100, 100, 100], ethers.utils.toUtf8Bytes(""));

    console.log("Done");
}

main().then(() => {
    process.exit(0);
}).catch((e) => {
    console.log(e);
    process.exit(-1);
});