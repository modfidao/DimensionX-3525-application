const {
  time,
  loadFixture,
} = require("@nomicfoundation/hardhat-network-helpers");
const hre = require("hardhat");
const { anyValue } = require("@nomicfoundation/hardhat-chai-matchers/withArgs");
const { expect } = require("chai");
const FactoryDeploy = require("./deploy/factory");
const ManagerDeploy = require("./deploy/manager");
const { ethers } = require("hardhat");

describe("Factory", function () {
  let Factory;
  let FactoryAddr;
  let Manager;
  let ManagerAddr;
  let Signers;

  beforeEach(async () => {
    Factory = await FactoryDeploy();
    FactoryAddr = Factory.address;

    Manager = await ManagerDeploy();
    ManagerAddr = Manager.address;

    Signers = await ethers.getSigners();
  });

  it("new dimensionX", async () => {
    const addr = await Factory.callStatic.newDimensionX(
      "3525A",
      "3525A",
      1,
      1000,
      Signers[1].address.toString(),
      ManagerAddr.toString()
    );

    await Factory.newDimensionX(
      "3525A",
      "3525A",
      1,
      1000,
      Signers[1].address,
      ManagerAddr
    );

    const bool = await Factory.isDimensionX(addr);
    expect(bool).to.equal(true);
  });
});
