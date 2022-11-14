const hre = require("hardhat")
const ethers = hre.ethers;

async function main() {
    const Manager = await ethers.getContractFactory("Manager");
    const ManagerInstance = await Manager.deploy();

    await ManagerInstance.deployed()
    
    return ManagerInstance;
}

module.exports =  main;