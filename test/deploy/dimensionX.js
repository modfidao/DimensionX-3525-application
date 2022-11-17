const hre = require("hardhat");
const ethers = hre.ethers;

async function main() {
  const DimensionX = await ethers.getContractFactory("DimensionX");

  const DimensionXInstance = await DimensionX.deploy();
  await DimensionXInstance.deployed();
  await DimensionXInstance.init(
    "3525A",
    "3525A",
    1,
    1000,
    "0x595b85b4A418e3B8df897D02F5BD49167D00862F",
    "0x595b85b4A418e3B8df897D02F5BD49167D00862F"
  );

  return DimensionXInstance;
}

module.exports = main;
