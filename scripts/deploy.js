// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// You can also run a script with `npx hardhat run <script>`. If you do that, Hardhat
// will compile your contracts, add the Hardhat Runtime Environment's members to the
// global scope, and execute the script.
const hre = require('hardhat');
const verify = require('./utils/verify');

async function main() {
  const Platform = await hre.ethers.getContractFactory('Platform');
  const PlatformInstance = await Platform.deploy();
  await PlatformInstance.deployed();

  const Factory = await hre.ethers.getContractFactory('Factory');
  const FactoryInstance = await Factory.deploy();
  await FactoryInstance.deployed();

  const DimensionX = await ethers.getContractFactory("DimensionX");
  const DimensionXInstance = await DimensionX.deploy();
  await DimensionXInstance.deployed();

  await FactoryInstance.setPlatform(PlatformInstance.address);

  const log = {
    Platform: PlatformInstance.address,
    Factory: FactoryInstance.address,
    DimensionX: DimensionXInstance.address,
  };

  const Verify = verify(hre);
  await Verify(log.Platform);
  await Verify(log.Factory);
  await Verify(log.DimensionX);

  console.table(log);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
