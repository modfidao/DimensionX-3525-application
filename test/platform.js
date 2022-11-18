const {
  time,
  loadFixture,
} = require("@nomicfoundation/hardhat-network-helpers");
const hre = require("hardhat");
const { anyValue } = require("@nomicfoundation/hardhat-chai-matchers/withArgs");
const { expect } = require("chai");
const PlatformDeploy = require("./deploy/platform");
const { ethers } = require("hardhat");

describe("platform test case", function (accounts) {
  let Platform;
  let PlatformAddr;
  let Signers;

  beforeEach(async () => {
    Platform = await PlatformDeploy();
    PlatformAddr = Platform.address;
    Signers = await ethers.getSigners();
  });

  it("deployer is the manager", async function () {
    const owner = await Platform.owner();
    const owner_ = Signers[0].address;
    expect(owner).to.equal(owner_);
  });

  it("can set manager fee", async () => {
    const fee = 100000000000;
    await Platform.changeManageFee(fee);
    const managerFee = await Platform.manageFee();

    expect(fee).to.equal(managerFee);
  });

  it("only manager can change manage fee", async () => {
    const fee = 100000000000;
    await Platform.connect(Signers[1])
      .changeManageFee(fee)
      .catch((e) => {
        expect(e.message).to.include("ERR_NOT_OWNER");
      });
  });

  it("manager receive native token", async () => {
    const sendValue = 10000;
    await Signers[1].sendTransaction({
      to: PlatformAddr,
      value: sendValue,
    });
    const balance = await ethers.provider.getBalance(PlatformAddr);
    expect(sendValue).to.equal(balance);
  });

  it("manager withdrew token", async () => {
    const sendValue = 10000;
    const defaultBalance = await Signers[1].getBalance();

    await Signers[0].sendTransaction({
      to: PlatformAddr,
      value: sendValue,
    });

    await Platform.connect(Signers[0]).withdrew(Signers[1].address, sendValue+1).catch(e=>{
      expect(e.message).to.include("ERR_NOT_ENOUGH")
    });

    await Platform.connect(Signers[0]).withdrew(Signers[1].address, sendValue);
    const afterBalance = await Signers[1].getBalance();

    const balance = await ethers.provider.getBalance(PlatformAddr);

    expect(afterBalance.sub(defaultBalance)).to.equal(sendValue);
    expect(balance).to.equal(0);
  });

  it("manager withdrew token", async () => {
    const sendValue = 10000;
    const defaultBalance = await Signers[1].getBalance();

    await Signers[0].sendTransaction({
      to: PlatformAddr,
      value: sendValue,
    });

    await Platform.connect(Signers[1])
      .withdrew(Signers[1].address, sendValue)
      .catch((e) => {
        expect(e.message).to.include("ERR_NOT_OWNER");
      });
  });

  it("change owner", async () => {
    await Platform.setOwner(Signers[1].address);
    const newOwner = await Platform.owner();

    expect(newOwner).to.equal(Signers[1].address);
  });

  it("change receiver", async () => {
    await Platform.setReceiver(Signers[1].address);
    const newReceiver = await Platform.receiver();

    expect(newReceiver).to.equal(Signers[1].address);
  });

  it("only owner can change to new owner", async () => {
    await Platform.connect(Signers[1])
      .setOwner(Signers[2].address)
      .catch((e) => {
        expect(e.message).to.include("ERR_NOT_OWNER");
      });
  });

  it("only owner can change to new receiver", async () => {
    await Platform.connect(Signers[1])
      .setReceiver(Signers[2].address)
      .catch((e) => {
        expect(e.message).to.include("ERR_NOT_OWNER");
      });
  });
});
