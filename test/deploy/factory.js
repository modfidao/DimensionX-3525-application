const hre = require("hardhat")
const ethers = hre.ethers;

async function main(params) {
    const Factory = await ethers.getContractFactory("Factory");
    const FactoryInstance = await Factory.deploy();

    await FactoryInstance.deployed()
    
    return FactoryInstance;
}

module.exports =  main;