const { hardhat } = require("hardhat");
const { expect } = require("chai");
const ethers = hardhat.ethers;

describe("Game Utility", () => {
    const contractNames = ["Marketplace", "MatchMaker", "ARENA", "BILIRA", "GOD", "SONS", "XP"];
    let contracts = {}
    let [signer, p1, p2];

    const deploy = async (factory, ...args) => {
        return await factory.deploy(...args);
    };

    beforeEach(async () => {

        [signer, p1, p2] = await ethers.getSigners();

        contractFactories = await Promise.all(contractNames.map(name =>
            ethers.getContractFactory(name).then(ctc => ctc.deployed())
        ));

        const arena = deploy(contractFactories[2]);
        const bilira = deploy(contractFactories[3]);
        const god = deploy(contractFactories[4]);
        const sons = deploy(contractFactories[5]);
        const xp = deploy(contractFactories[6]);

        const marketplace = deploy(
            contractFactories[0],
            arena.address,
            god.adress,
            sons.address,
            bilira.address
        );

        const matchMaker = deploy(
            contractFactories[1],
            xp.address,
            arena.address,
            sons.address,
            bilira.address,
            god.address
        );

        contracts = { arena, bilira, god, sons, xp, marketplace, matchMaker };
    });

    it("Plays a game", async () => {
        const { arena, bilira, god, sons, xp, marketplace, matchMaker } = contracts;

        const Warrior = [true, 0, 1, 1, 1, 4, 2]
        const Archer = [true, 0, 3, 3, 1, 2, 1]
        const Wizard = [true, 0, 2, 2, 2, 2, 3]
        const Healer = [true, 1, 2, 2, 3, 4, 2]
        const Titan = [true, 0, 1, 1, 4, 5, 3]

        const Arena1 = [3, 900, 30, ethers.utils.parseEther("100")]
        const Arena2 = [3, 900, 30, ethers.utils.parseEther("100")]
        const Arena3 = [3, 900, 30, ethers.utils.parseEther("100")]
        const Arena4 = [4, 900, 30, ethers.utils.parseEther("100")]
        const Arena5 = [5, 900, 30, ethers.utils.parseEther("100")]

        god.registerType(1, Warrior);
        god.registerType(2, Archer);
        god.registerType(3, Wizard);
        god.registerType(4, Healer);
        god.registerType(5, Titan);

        arena.mint(signer.address, 1, Arena1);
        arena.mint(signer.address, 2, Arena2);
        arena.mint(signer.address, 3, Arena3);
        arena.mint(signer.address, 4, Arena4);

        expect(arena.balanceOf(signer.address)).to.be.eq(4);
    })
});