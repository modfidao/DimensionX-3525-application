const {
    time,
    loadFixture,
  } = require("@nomicfoundation/hardhat-network-helpers");
  const hre = require("hardhat");
  const { anyValue } = require("@nomicfoundation/hardhat-chai-matchers/withArgs");
  const { expect } = require("chai");
  const DimensionXDeploy = require("./deploy/dimensionX");
  const { ethers } = require("hardhat");
  
  describe("Factory", function () {
    let DimensionX;
  
    beforeEach(async () => {
        DimensionX = await DimensionXDeploy();
    });
  

    it("DimensionX only init once after deployed",async()=>{
        await DimensionX.init(
            "3525A",
            "3525A",
            1,
            1000,
            "0x595b85b4A418e3B8df897D02F5BD49167D00862F",
            "0x595b85b4A418e3B8df897D02F5BD49167D00862F"
          ).catch(e=>{
            expect(e.message).to.include("ERR_INITIALIZED")
          });
    })
  });
  