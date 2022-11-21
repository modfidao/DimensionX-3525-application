const DimensionXDeploy = require("./deploy/dimensionX");
const PlatformDeploy = require("./deploy/platform");

describe("dimensionX deploy test", function () {

  it("deploy dimensionX by init func", async () => {
    const Platform = await PlatformDeploy();
    const Signers = await ethers.getSigners();
    const instance =  await DimensionXDeploy(Signers[0].address,Platform.address);

    await Signers[1].sendTransaction({
      to: instance.address,
      value: 100000,
    });

    await instance.userWithdrew()
  });
});
