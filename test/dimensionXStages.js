const { expect } = require('chai');
const { ethers } = require('hardhat');
const { BigNumber } = ethers;

const DimensionXDeploy = require('./deploy/dimensionX');
const PlatformDeploy = require('./deploy/platform');

const calGasUsed = require('./utils/calGasUsed');
const calBNPercent = require('./utils/calBNPercent');

describe('3 stage to claim reward with complex transferred', () => {
  let DimensionX;
  let Platform;
  let Signers;

  let PlatformAddr;
  let deployer, other;
  const sendValue = BigNumber.from(1).mul(10).pow(18);
  const sendValue2 = BigNumber.from(5).mul(10).pow(18);

  before(async () => {
    Signers = await ethers.getSigners();
    Platform = await PlatformDeploy();
    DimensionX = await DimensionXDeploy(Signers[0].address, Platform.address);

    PlatformAddr = Platform.address;
    [deployer, other] = [Signers[0], Signers[1]];

    await Signers[0].sendTransaction({
      to: DimensionX.address,
      value: sendValue,
    });

    await DimensionX.addSlotWhite(2);
    await DimensionX.addSlotWhite(3);
    await DimensionX.addSlotWhite(5);
    await DimensionX.addSlotWhite(10);
    await DimensionX.addSlotWhite(50);
    await DimensionX.addSlotWhite(100);
    await DimensionX.changeManager(Signers[5].address);
  });

  it('1 stage: clime reward ', async () => {
    await DimensionX.composeOrSplitToken(1, 3, 300);

    const bBal = await deployer.getBalance();
    const gasUsed = await calGasUsed(DimensionX.userWithdrew);
    const aBal = await deployer.getBalance();

    const txReceive = aBal.sub(bBal).add(gasUsed);
    expect(calBNPercent(sendValue, 0.945)).to.equal(txReceive);
  });

  it('2 stage: vault receive eth', async () => {
    await Signers[3].sendTransaction({
      to: DimensionX.address,
      value: sendValue2,
    });
  });

  it('3 stage: transfer token and reward', async () => {});
});
