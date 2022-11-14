const hre = require("hardhat")
const ethers = hre.ethers;

async function main(params) {
    const Manager = await ethers.getContractFactory("Manager");
    const ManagerInstance = await Manager.deploy();

    await ManagerInstance.deployed()

    console.log("Manager deployed.")

    return ManagerInstance;
}

module.exports =  main;