const hardhat = require("hardhat");
const ethers = hardhat.ethers;

const ADDR = require("./addresses");

async function main() {
    const signer = await ethers.getSigner();

    const SonsFactory = await ethers.getContractFactory("SONS");
    const BiliraFactory = await ethers.getContractFactory("BILIRA");

    const Sons = SonsFactory.attach(ADDR.Sons);
    const Bilira = BiliraFactory.attach(ADDR.Bilira);

    const addr1 = "0x1070cF71bEFe2D83faE5CfD337f5A118F61F227f";
    const addr2 = "0xd0c3386D693A303f66cE76C79CD1549DFB5F1e0D";
    const ulas = "0x55aEd0ce035883626e536254dda2F23a5b5D977f";


    await Sons.connect(signer).mint(addr1, ethers.utils.parseEther("100000"));
    await Sons.connect(signer).mint(signer.address, ethers.utils.parseEther("100000"));
    await Sons.connect(signer).mint(addr2, ethers.utils.parseEther("100000"));
    await Sons.connect(signer).mint(ulas, ethers.utils.parseEther("100000"));
    await Bilira.connect(signer).mint(addr1, ethers.utils.parseEther("100000"));
    await Bilira.connect(signer).mint(signer.address, ethers.utils.parseEther("100000"));
    await Bilira.connect(signer).mint(addr2, ethers.utils.parseEther("100000"));

    console.log("Done");
}

main().then(() => {
    process.exit(0);
}).catch((e) => {
    console.log(e);
    process.exit(-1);
});