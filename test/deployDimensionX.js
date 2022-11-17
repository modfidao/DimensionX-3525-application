const DimensionXDeploy = require("./deploy/dimensionX");

describe("dimensionX", function () {

  it("deploy dimensionX by init func", async () => {
    await DimensionXDeploy();
  });
});
