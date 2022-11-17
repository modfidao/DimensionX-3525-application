const hre = require("hardhat");
const ethers = hre.ethers;

async function main(deployer = "0x595B85B4A418E3B8DF897D02F5BD49167D00862F") {
  const DimensionX = await ethers.getContractFactory("DimensionX");
  const DimensionXInstance = await DimensionX.deploy();

  await DimensionXInstance.deployed();
  await DimensionXInstance.init(
    "3525A",
    "3525A",
    1,
    1000,
    deployer,
    "0x70997970C51812DC3A010C7D01B50E0D17DC79C8"
  );

  return DimensionXInstance;
}

module.exports = main;
