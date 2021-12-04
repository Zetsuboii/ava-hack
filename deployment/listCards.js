const hardhat = require("hardhat");
const ethers = hardhat.ethers;

const ADDR = require("./addresses");

async function main() {
    const signer = await ethers.getSigner();
    const GodFactory = await ethers.getContractFactory("GOD");
    const MarketplaceFactory = await ethers.getContractFactory("Marketplace");

    const God = GodFactory.attach(ADDR.God);
    const Marketplace = MarketplaceFactory.attach(ADDR.Marketplace);

    const addr1 = "0x1070cF71bEFe2D83faE5CfD337f5A118F61F227f";
    const addr2 = "0xd0c3386D693A303f66cE76C79CD1549DFB5F1e0D";

    const sleep = async (n) => await new Promise(res => {
        console.log("OK.");
        setTimeout(res, n * 1000);
    });

    await God.connect(signer).mint(signer.address, 4, 5, ethers.utils.toUtf8Bytes(""));
    await sleep(2);
    await God.connect(signer).setApprovalForAll(Marketplace.address, true);
    await sleep(2);
    await Marketplace.connect(signer).listGod(4, 5, 0, 100);
    console.log("Done");
}

main().then(() => {
    process.exit(0);
}).catch((e) => {
    console.log(e);
    process.exit(-1);
});