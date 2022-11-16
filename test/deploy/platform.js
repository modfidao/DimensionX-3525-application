const hre = require("hardhat")
const ethers = hre.ethers;

async function main() {
    const Platform = await ethers.getContractFactory("Platform");
    const PlatformInstance = await Platform.deploy();

    await PlatformInstance.deployed()
    
    return PlatformInstance;
}

module.exports =  main;