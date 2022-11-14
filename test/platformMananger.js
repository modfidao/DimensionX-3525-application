const {
  time,
  loadFixture,
} = require("@nomicfoundation/hardhat-network-helpers");
const hre = require("hardhat");
const { anyValue } = require("@nomicfoundation/hardhat-chai-matchers/withArgs");
const { expect, should, assert } = require("chai");
const ManagerDeploy = require("./deploy/mananger");
const { ethers } = require("hardhat");

describe("Platform Manager", function (accounts) {
  let Manager;
  let ManagerAddr;
  let Signers;

  beforeEach(async () => {
    Manager = await ManagerDeploy();
    ManagerAddr = Manager.address;
    Signers = await ethers.getSigners();
  });

  it("deployer is the manager", async function () {
    const manager = await Manager.manager();
    const manager_ = Signers[0].address;
    expect(manager).to.equal(manager_);
  });

  it("can set manager fee", async () => {
    const fee = 100000000000;
    await Manager.changeManageFee(fee);
    const managerFee = await Manager.manageFee();

    expect(fee).to.equal(managerFee);
  });

  it("only manager can change manage fee", async () => {
    const fee = 100000000000;
    await Manager.connect(Signers[1])
      .changeManageFee(fee)
      .catch((e) => {
        expect(e.message).to.include("ERR_NOT_OWNER");
      });
  });

  it("manager receive native token", async () => {
    const sendValue = 10000;
    await Signers[1].sendTransaction({
      to: ManagerAddr,
      value: sendValue,
    });
    const balance = await ethers.provider.getBalance(ManagerAddr);
    expect(sendValue).to.equal(balance);
  });

  it("manager withdrew token", async () => {
    const sendValue = 10000;
    const defaultBalance = await Signers[1].getBalance();

    await Signers[0].sendTransaction({
      to: ManagerAddr,
      value: sendValue,
    });

    await Manager.connect(Signers[0]).withdrew(Signers[1].address, sendValue);
    const afterBalance = await Signers[1].getBalance();

    const balance = await ethers.provider.getBalance(ManagerAddr);

    expect(afterBalance.sub(defaultBalance)).to.equal(sendValue);
    expect(balance).to.equal(0);
  });

  it("manager withdrew token", async () => {
    const sendValue = 10000;
    const defaultBalance = await Signers[1].getBalance();

    await Signers[0].sendTransaction({
      to: ManagerAddr,
      value: sendValue,
    });

    await Manager.connect(Signers[1])
      .withdrew(Signers[1].address, sendValue)
      .catch((e) => {
        expect(e.message).to.include("ERR_NOT_OWNER");
      });
  });
});
