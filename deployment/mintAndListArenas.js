const fs = require("fs");
const hardhat = require("hardhat");
const ethers = hardhat.ethers;

async function main() {
    const signer = await ethers.getSigner();
    const ArenaFactory = await ethers.getContractFactory("ARENA");
    const MarketplaceFactory = await ethers.getContractFactory("Marketplace");

    const Arena = ArenaFactory.attach("0x5F9DEaA5da071E3fE8d83ad06C8c8dAE0ACc66F0");
    const Marketplace = MarketplaceFactory.attach("0x74448d789397180d9a08a3793E86B366A3C178a2");

    const addr1 = "0x1070cF71bEFe2D83faE5CfD337f5A118F61F227f";
    const addr2 = "0xd0c3386D693A303f66cE76C79CD1549DFB5F1e0D";

    // await Arena.connect(signer).mint(signer.address, 0, [3, 900, 30, ethers.utils.parseEther("100")]);
    // await Arena.connect(signer).mint(addr1, 1, [3, 900, 30, ethers.utils.parseEther("100")]);
    // await Arena.connect(signer).mint(addr2, 2, [3, 900, 30, ethers.utils.parseEther("100")]);
    await Arena.connect(signer).mint(signer.address, 3, [4, 900, 30, ethers.utils.parseEther("100")]);
    await Arena.connect(signer).mint(signer.address, 4, [5, 900, 30, ethers.utils.parseEther("100")]);

    // await Marketplace.connect(signer).listArena(0, 0, ethers.utils.parseEther("500"));
    await Marketplace.connect(signer).listArena(3, 0, ethers.utils.parseEther("1000"));
    await Marketplace.connect(signer).listArena(4, 0, ethers.utils.parseEther("2000"));

    console.log("Done");
}

main().then(() => {
    process.exit(0);
}).catch((e) => {
    console.log(e);
    process.exit(-1);
});