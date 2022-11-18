const DimensionXDeploy = require("./deploy/dimensionX");
const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("vault config test", function () {
  let DimensionX;
  let Signers;

  beforeEach(async () => {
    Signers = await ethers.getSigners();
    DimensionX = await DimensionXDeploy(Signers[0].address);
  });

  it("manager from set args", async () => {
    const newManager = Signers[1].address;

    DimensionX = await DimensionXDeploy(newManager);
    const manager = await DimensionX.manager();

    expect(manager).to.equal(newManager);
  });

  it("can changed Manager", async () => {
    const newManger = Signers[1].address;
    await DimensionX.changeManager(newManger);

    const manager = await DimensionX.manager();
    expect(manager).to.equal(newManger);
  });

  it("can not change to new manager who not manager", async () => {
    const newManger = Signers[1].address;
    await DimensionX.connect(Signers[1])
      .changeManager(newManger)
      .catch((e) => {
        expect(e.message).to.include("ERR_NOT_MANAGER");
      });
  });

  it("changed and got manager fee", async () => {
    const newFee = 1000;
    await DimensionX.changeManageFee(newFee);
    const fee = await DimensionX.manageFee();

    expect(newFee).to.equal(fee);
  });

  it("could change manage fee who manager are", async () => {
    const fee = 1000;
    await DimensionX.connect(Signers[1])
      .changeManageFee(fee)
      .catch((e) => {
        expect(e.message).to.include("ERR_NOT_MANAGER");
      });
  });
});
