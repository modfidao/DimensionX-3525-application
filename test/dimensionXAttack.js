const DimensionXDeploy = require('./deploy/dimensionX');
const PlatformDeploy = require('./deploy/platform');
const AttackDeploy = require('./deploy/attack');
const { ethers } = require('hardhat');
const { expect } = require('chai');

const { BigNumber } = ethers;

describe('dimensionX safe test', function () {
  let DimensionX;
  let Signers;
  let Attack;

  it('attack dimensionX', async () => {
    Signers = await ethers.getSigners();

    const Platform = await PlatformDeploy();
    DimensionX = await DimensionXDeploy(Signers[0].address, Platform.address);
    Attack = await AttackDeploy(DimensionX.address);

    await Signers[1].sendTransaction({
      to: DimensionX.address,
      value: BigNumber.from(10).pow(18).mul(1),
    });

    await Platform.setReceiver(Attack.address);
    await DimensionX['transferFrom(uint256,address,uint256)'](1, Attack.address, 30);

    await Attack.attack().catch(e=>{
        expect(e.message).to.include("ERR_WITHDREW_FAILED")
    });
  });
});
