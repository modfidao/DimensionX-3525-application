const {
    time,
    loadFixture,
  } = require("@nomicfoundation/hardhat-network-helpers");
  const hre = require("hardhat");
  const { anyValue } = require("@nomicfoundation/hardhat-chai-matchers/withArgs");
  const { expect } = require("chai");
  const FactoryDeploy = require("./deploy/factory");
  const PlatformDeploy = require("./deploy/dimensionX");
  const { ethers } = require("hardhat");
  
  describe("Factory", function () {
    let Factory;
    let FactoryAddr;
    let Platform;
    let PlatformAddr;
    let Signers;
  
    beforeEach(async () => {
      Factory = await FactoryDeploy();
      FactoryAddr = Factory.address;
  
      Platform = await PlatformDeploy();
      PlatformAddr = Platform.address;
  
      Signers = await ethers.getSigners();
    });
  

    it("ddd",async()=>{})
  });
  