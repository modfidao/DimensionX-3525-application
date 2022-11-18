const { expect } = require('chai');
const { ethers } = require('hardhat');
const { BigNumber } = ethers;

const DimensionXDeploy = require('./deploy/dimensionX');
const PlatformDeploy = require('./deploy/platform');

describe('dimensionX reward test', function () {
  let DimensionX;
  let Platform;
  let Signers;

  let DimensionXAddr;
  let PlatformAddr;
  let deployer, other;
  const sendValue = BigNumber.from(1).mul(10).pow(18);

  beforeEach(async () => {
    Signers = await ethers.getSigners();
    Platform = await PlatformDeploy();
    DimensionX = await DimensionXDeploy(Signers[0].address, Platform.address);

    DimensionXAddr = DimensionX.address;
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
      const tokenId = await DimensionX.callStatic.composeOrSplitToken(1, 3, 100);
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
  describe('1 wallet to claim reward', function () {
    it('vault value match', async () => {
      const value = await ethers.provider.getBalance(DimensionX.address);
      expect(value).to.equal(sendValue);
    });
    it('[share=100%] reward once', async () => {
      // b-before;
      // a-after;
      // bal-balance
      const bBalManager = await other.getBalance();
      const bBalDeployer = await deployer.getBalance();

      const tx1 = await DimensionX.changeManager(other.address);
      const tx2 = await DimensionX.userWithdrew();

      const aBalManager = await other.getBalance();
      const aBalDeployer = await deployer.getBalance();
      const aBalPlatform = await ethers.provider.getBalance(PlatformAddr);

      console.log(aBalDeployer.sub(bBalDeployer).add(tx1.gasLimit).add(tx2.gasLimit));
      expect(sendValue.mul(30).div(1000)).to.equal(aBalPlatform);
      expect(sendValue.mul(25).div(1000)).to.equal(aBalManager.sub(bBalManager));
    });
  });
});
