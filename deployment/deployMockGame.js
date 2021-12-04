const hardhat = require("hardhat");
const ethers = hardhat.ethers;

const ADDR = require("./addresses");

async function main() {
    const signer = await ethers.getSigner();
    const XPFactory = await ethers.getContractFactory("XP");
    const SonsFactory = await ethers.getContractFactory("SONS");
    const GodFactory = await ethers.getContractFactory("GOD");
    const ClashFactory = await ethers.getContractFactory("Clash");

    const Arena = [3, 900, 30, ethers.utils.parseEther("100")];
    const arenaOwner = signer.address;
    const addressOne = "0x1070cF71bEFe2D83faE5CfD337f5A118F61F227f";
    const addressTwo = "0xd0c3386D693A303f66cE76C79CD1549DFB5F1e0D";
    const deckOne = [1, 3, 2, 4, 3];
    const deckTwo = [2, 3, 4, 4, 1];

    /*  XP xpAddress,
         SONS sonsAddress,
         GOD godAddress,
         ArenaDetails memory arena,
         address arenaOwner,
         address addressOne,
         address addressTwo,
         uint8[] memory deckOne,
         uint8[] memory deckTwo */

    const XP = await XPFactory.deploy();
    await XP.deployed();

    const Sons = await SonsFactory.deploy();
    await Sons.deployed();

    const God = await GodFactory.deploy();
    await God.deployed();

    const Clash = await ClashFactory.deploy(
        XP.address,
        Sons.address,
        God.address,
        Arena,
        arenaOwner,
        addressOne,
        addressTwo,
        deckOne,
        deckTwo
    );
    await Clash.deployed();
    console.log(Clash.address);

}

main().then(() => {
    process.exit(0);
}).catch((e) => {
    console.log(e);
    process.exit(-1);
});