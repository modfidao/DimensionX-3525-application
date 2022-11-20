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
  const sendValue = BigNumber.from(10).pow(18).mul(1);
  const sendValue2 = BigNumber.from(10).pow(18).mul(5);

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
    // total share 1000
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

  it('3 stage: transfer token and reward', async () => {
    await DimensionX.composeOrSplitToken(1, 3, 300);
    // 【before】
    // user1 | share 1000
    //       | token1-slot1-700
    //       | token2-slot3-100
    //       | has reward 1 * 10 ** 18 * 0.945

    // 【after】
    // user1 | share 700
    //       | token1-slot-550
    //       | token2-slot-50
    // user2 | share 300
    //       | token1-slot1-150
    //       | token2-slot3-50
    await DimensionX['transferFrom(uint256,address,uint256)'](1, other.address, 180);
    await DimensionX['transferFrom(uint256,address,uint256)'](2, other.address, 40);

    // user1
    const bBal1 = await deployer.getBalance();
    const gasUsed1 = await calGasUsed(DimensionX.userWithdrew);
    const aBal1 = await deployer.getBalance();

    const getReward = aBal1.sub(bBal1).add(gasUsed1);
    expect(calBNPercent(sendValue2, 0.7 * 0.945)).to.equal(getReward);

    // user2
    const bBal2 = await other.getBalance();
    const gasUsed2 = await calGasUsed(DimensionX.connect(other).userWithdrew);
    const aBal2 = await other.getBalance();
    const getReward2 = aBal2.sub(bBal2).add(gasUsed2);

    expect(calBNPercent(sendValue2,0.3*0.945)).equal(getReward2)
    expect(calBNPercent(sendValue2, 0.945)).to.equal(getReward2.add(getReward));
  });
});
