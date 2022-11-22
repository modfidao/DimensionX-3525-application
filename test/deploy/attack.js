const hre = require("hardhat")
const ethers = hre.ethers;

async function main(DimensionX) {
    const Attack = await ethers.getContractFactory("Attack");
    const AttackInstance = await Attack.deploy();

    await AttackInstance.deployed()
    await AttackInstance.init(DimensionX)

    return AttackInstance;
}

module.exports =  main;