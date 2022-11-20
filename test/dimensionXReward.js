const { expect } = require('chai');
const { ethers } = require('hardhat');
const { BigNumber } = ethers;

const DimensionXDeploy = require('./deploy/dimensionX');
const PlatformDeploy = require('./deploy/platform');

const calGasUsed = require('./utils/calGasUsed');
const calBNPercent = require('./utils/calBNPercent');

describe('dimensionX reward test', function () {
  let DimensionX;
  let Platform;
  let Signers;

  let PlatformAddr;
  let deployer, other;
  const sendValue = BigNumber.from(10).pow(18).mul(1);

  beforeEach(async () => {
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
  });

  describe('token compose and split', function () {
    it('[FULL] compose token 1000/1 => 333/3', async () => {
      const tokenId = await DimensionX.callStatic.composeOrSplitToken(1, 3, 1000);
      await DimensionX.composeOrSplitToken(1, 3, 1000);

      await DimensionX['balanceOf(uint256)'](1).catch((e) => {
        expect(e.message).to.include('ERC3525: invalid token ID');
      });
      const balance2 = await DimensionX['balanceOf(uint256)'](tokenId);

      expect(balance2).to.equal(333);
    });

    it('[FULL] split token 100/5 => 250/2 => ', async () => {
      const tokenId5 = await DimensionX.callStatic.composeOrSplitToken(1, 5, 500);
      await DimensionX.composeOrSplitToken(1, 5, 500);

      const tokenId2 = await DimensionX.callStatic.composeOrSplitToken(tokenId5, 2, 100);
      await DimensionX.composeOrSplitToken(tokenId5, 2, 100);

      const balance2 = await DimensionX['balanceOf(uint256)'](tokenId2);
      await DimensionX['balanceOf(uint256)'](tokenId5).catch((e) => {
        expect(e.message).to.include('ERC3525: invalid token ID');
      });

      expect(balance2).to.equal(250);
    });

    it('[NOT FULL] compose token 10/3 => 3/10', async () => {
      // 1000/1 => 333/3
      const tokenId3 = await DimensionX.callStatic.composeOrSplitToken(1, 3, 1000);
      await DimensionX.composeOrSplitToken(1, 3, 1000);

      // 10/3 => 3/10
      const tokenId10 = await DimensionX.callStatic.composeOrSplitToken(2, 10, 10);
      await DimensionX.composeOrSplitToken(2, 10, 10);

      const balance3 = await DimensionX['balanceOf(uint256)'](tokenId3);
      const balance10 = await DimensionX['balanceOf(uint256)'](tokenId10);

      expect(333 - 10).to.equal(balance3);
      expect(3).to.equal(balance10);
    });

    it('[NOT FULL] split token 10/5 => 25/2', async () => {
      const tokenId5 = await DimensionX.callStatic.composeOrSplitToken(1, 5, 500);
      await DimensionX.composeOrSplitToken(1, 5, 500);

      const tokenId2 = await DimensionX.callStatic.composeOrSplitToken(tokenId5, 2, 10);
      await DimensionX.composeOrSplitToken(tokenId5, 2, 10);

      const balance2 = await DimensionX['balanceOf(uint256)'](tokenId2);
      const balance5 = await DimensionX['balanceOf(uint256)'](tokenId5);

      expect(balance2).to.equal(25);
      expect(balance5).to.equal(100 - 10);
    });
  });

  describe('1～2 wallet to claim reward', function () {
    it('vault value match', async () => {
      const value = await ethers.provider.getBalance(DimensionX.address);
      expect(value).to.equal(sendValue);
    });
    it('[share=100%] reward once', async () => {
      // b-before;
      // a-after;
      // bal-balance
      await DimensionX.changeManager(other.address);
      const bBalManager = await other.getBalance();
      const bBalDeployer = await deployer.getBalance();

      const txGasUsed = await calGasUsed(DimensionX.userWithdrew);

      const aBalManager = await other.getBalance();
      const aBalDeployer = await deployer.getBalance();
      const aBalPlatform = await ethers.provider.getBalance(PlatformAddr);

      // usedGas = cumulativeGasUsed * effectiveGasPrice;
      const userReward = aBalDeployer.sub(bBalDeployer).add(txGasUsed);
      expect(calBNPercent(sendValue, 0.945)).to.equal(userReward);
      expect(calBNPercent(sendValue, 0.03)).to.equal(aBalPlatform);
      expect(calBNPercent(sendValue, 0.025)).to.equal(aBalManager.sub(bBalManager));
    });

    it('[share=75%] reward once', async () => {
      await DimensionX.changeManager(Signers[2].address);
      await DimensionX['transferFrom(uint256,address,uint256)'](1, other.address, 250);

      const bBalPla = await ethers.provider.getBalance(Platform.address); // platform fee
      const bBalCre = await Signers[2].getBalance(); // creator fee

      // user1
      const bBalUser1 = await deployer.getBalance();
      const tx1GasUsed = await calGasUsed(DimensionX.userWithdrew);
      const aBalUser1 = await deployer.getBalance();

      const tx1RewardAmount = calBNPercent(sendValue, 0.75);
      const tx1ReceiveAmount = aBalUser1.sub(bBalUser1).add(tx1GasUsed);
      expect(tx1ReceiveAmount).to.equal(calBNPercent(tx1RewardAmount, 0.945));

      // user2
      const bBalUser2 = await other.getBalance();
      const tx2GasUsed = await calGasUsed(DimensionX.connect(other).userWithdrew);
      const aBalUser2 = await other.getBalance();
      const tx2RewardAmount = calBNPercent(sendValue, 0.25);
      const tx2ReceiveAmount = aBalUser2.sub(bBalUser2).add(tx2GasUsed);
      expect(tx2ReceiveAmount).to.equal(calBNPercent(tx2RewardAmount, 0.945));

      const aBalPla = await ethers.provider.getBalance(Platform.address); // platform fee
      const aBalCre = await Signers[2].getBalance(); // creator fee

      const calBalPla = aBalPla.sub(bBalPla);
      const calBalCre = aBalCre.sub(bBalCre);
      expect(calBalPla).to.equal(calBNPercent(sendValue, 0.03));
      expect(calBalCre).to.equal(calBNPercent(sendValue, 0.025));
    });

    it('[share=75.5%] reward once', async () => {
      await DimensionX.changeManager(Signers[2].address);
      await DimensionX['transferFrom(uint256,address,uint256)'](1, other.address, 245);

      const bBalPla = await ethers.provider.getBalance(Platform.address); // platform fee
      const bBalCre = await Signers[2].getBalance(); // creator fee

      // user1
      const bBalUser1 = await deployer.getBalance();
      const tx1GasUsed = await calGasUsed(await DimensionX.userWithdrew);
      const aBalUser1 = await deployer.getBalance();

      const tx1RewardAmount = calBNPercent(sendValue, 0.755);
      const tx1ReceiveAmount = aBalUser1.sub(bBalUser1).add(tx1GasUsed);
      expect(tx1ReceiveAmount).to.equal(calBNPercent(tx1RewardAmount, 0.945));

      // user2
      const bBalUser2 = await other.getBalance();
      const tx2GasUsed = await calGasUsed(DimensionX.connect(other).userWithdrew);
      const aBalUser2 = await other.getBalance();
      const tx2RewardAmount = calBNPercent(sendValue, 0.245);
      const tx2ReceiveAmount = aBalUser2.sub(bBalUser2).add(tx2GasUsed);
      expect(tx2ReceiveAmount).to.equal(calBNPercent(tx2RewardAmount, 0.945));

      const aBalPla = await ethers.provider.getBalance(Platform.address); // platform fee
      const aBalCre = await Signers[2].getBalance(); // creator fee

      const calBalPla = aBalPla.sub(bBalPla);
      const calBalCre = aBalCre.sub(bBalCre);
      expect(calBalPla).to.equal(calBNPercent(sendValue, 0.03));
      expect(calBalCre).to.equal(calBNPercent(sendValue, 0.025));
    });
  });
});
