const { expect } = require("chai");
const { ethers } = require("hardhat");

const DimensionXDeploy = require("./deploy/dimensionX");
const PlatformDeploy = require("./deploy/platform");

describe("dimensionX basic config", function () {
  let DimensionX;
  let Platform;
  let Signers;

  let DimensionXAddr;
  let PlatformAddr;
  let deployer, other;

  before(async () => {
    Signers = await ethers.getSigners();
    Platform = await PlatformDeploy();
    DimensionX = await DimensionXDeploy(Signers[0].address, Platform.address);

    DimensionXAddr = DimensionX.address;
    PlatformAddr = Platform.address;
    [deployer, other] = [Signers[0].address, Signers[1].address];
  });

  it("init data is match", async () => {
    const shareTotal = await DimensionX.shareSupply();
    const manager = await DimensionX.manager();
    const platform = await DimensionX.Platform();

    expect(shareTotal).to.equal(1000);
    expect(manager).to.equal(deployer);
    expect(platform).to.equal(PlatformAddr);
  });

  it("init must mint once, and token id is 1", async () => {
    const shareTotal = await DimensionX.shareSupply();
    const balance = await DimensionX["balanceOf(uint256)"](1);
    expect(shareTotal).to.equal(balance);
  });

  it("add some slot", async () => {
    await DimensionX.addSlotWhite(2);
    await DimensionX.addSlotWhite(5);
    await DimensionX.addSlotWhite(10);
    await DimensionX.addSlotWhite(50);
    await DimensionX.addSlotWhite(100);

    const slot2 = await DimensionX.slotWhite(2);
    const slot5 = await DimensionX.slotWhite(5);
    const slot10 = await DimensionX.slotWhite(10);
    const slot50 = await DimensionX.slotWhite(50);
    const slot100 = await DimensionX.slotWhite(100);

    const stateTotal = slot2 && slot5 && slot10 && slot50 && slot100;

    expect(stateTotal).to.equal(true);
  });

  it("only manager can add token slot", async () => {
    await DimensionX.connect(Signers[1])
      .addSlotWhite(2)
      .catch((e) => {
        expect(e.message).to.include("ERR_NOT_MANAGER");
      });
  });

  it("slot can not be zero",async()=>{
    await DimensionX.callStatic.addSlotWhite(0).catch(e=>{
      expect(e.message).to.include("ERR_CANT_BE_ZERO")
    })
  })

  it("token could not compose that not add to white token", async () => {
    await DimensionX.composeOrSplitToken(1, 3, 50).catch((e) => {
      expect(e.message).to.include("ERR_NOT_WHITE_SLOT");
    });
  });

  it("compose token, 100/1 => 50/2", async () => {
    const tokenId = await DimensionX.callStatic.composeOrSplitToken(1, 2, 100);
    await DimensionX.composeOrSplitToken(1, 2, 100);
    const balance1 = await DimensionX["balanceOf(uint256)"](1);
    const balance2 = await DimensionX["balanceOf(uint256)"](tokenId);

    expect(100).to.equal(1000 - balance1.toNumber());
    expect(100 / 2).to.equal(balance2);
  });

  it("compose token, 50/2 => 10/10", async () => {
    const tokenId = await DimensionX.callStatic.composeOrSplitToken(2, 10, 50);
    await DimensionX.composeOrSplitToken(2, 10, 50);

    await DimensionX["balanceOf(uint256)"](2).catch((e) => {
      expect(e.message).to.include("ERC3525: invalid token ID");
    });

    const balance = await DimensionX["balanceOf(uint256)"](tokenId);

    expect(balance).to.equal(10);
  });

  it("only manager can remove slot", async () => {
    await DimensionX.connect(Signers[1])
      .removeSlotWhite(2)
      .catch((e) => {
        expect(e.message).to.include("ERR_NOT_MANAGER");
      });
  });

  it("manager can remove slot", async () => {
    await DimensionX.removeSlotWhite(10);
  });

  it("can not compose when not white slot", async () => {
    await DimensionX.callStatic.composeOrSplitToken(1, 10, 50).catch((e) => {
      expect(e.message).to.include("ERR_NOT_WHITE_SLOT");
    });
  });

  it("can not remove not exit token", async () => {
    await DimensionX.removeSlotWhite(10).catch((e) => {
      expect(e.message).to.include("ERR_HAS_NOT_WHITE");
    });
  });

  it("transfer token to vault", async () => {
    const sendValue = 10000000;

    await Signers[0].sendTransaction({
      to: DimensionX.address,
      value: sendValue,
    });

    const balance = await ethers.provider.getBalance(DimensionX.address);

    expect(balance.toNumber()).to.equal(sendValue);
  });

  it("user withdrew",async ()=>{
    await DimensionX.userWithdrew()
  })
});
