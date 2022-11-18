const DimensionXDeploy = require("./deploy/dimensionX");

describe("dimensionX deploy test", function () {

  it("deploy dimensionX by init func", async () => {
    await DimensionXDeploy();
  });
});
