const {
  time,
  loadFixture,
} = require("@nomicfoundation/hardhat-network-helpers");
const hre = require("hardhat");
const { anyValue } = require("@nomicfoundation/hardhat-chai-matchers/withArgs");
const { expect } = require("chai");
const FactoryDeploy = require("./deploy/factory");
const PlatformDeploy = require("./deploy/platform");
const { ethers } = require("hardhat");

describe("factory to create Dimension X", function () {
  let Factory;
  let FactoryAddr;
  let Platform;
  let PlatformAddr;
  let Signers;

  beforeEach(async () => {
    Factory = await FactoryDeploy();
    FactoryAddr = Factory.address;

    Platform = await PlatformDeploy();
    PlatformAddr = Platform.address;

    Signers = await ethers.getSigners();
    await Factory.setPlatform(PlatformAddr);
  });

  it("new dimensionX", async () => {
    const addr = await Factory.callStatic.newDimensionX(
      "3525A",
      "3525A",
      1,
      1000,
      Signers[1].address
    );

    await Factory.newDimensionX(
      "3525A",
      "3525A",
      1,
      1000,
      Signers[1].address
    );

    const bool = await Factory.isDimensionX(addr);
    expect(bool).to.equal(true);
  });
});
