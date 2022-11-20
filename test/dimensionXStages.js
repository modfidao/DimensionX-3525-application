describe("3 stage to claim reward with complex transferred", async ()=>{
    let DimensionX;
    let Platform;
    let Signers;
  
    let PlatformAddr;
    let deployer, other;
    const sendValue = BigNumber.from(1).mul(10).pow(18);
  
    before(async () => {
      Signers = await ethers.getSigners();
      Platform = await PlatformDeploy();
      DimensionX = await DimensionXDeploy(Signers[5].address, Platform.address);
  
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

    it("1 stage: clime reward ", async ()=>{
        await DimensionX.composeOrSplitToken(1, 3, 300);
  
        const bBal = await deployer.getBalance()
        const tx = await DimensionX.userWithdrew()
        const txCal = await tx.wait()
        const aBal = await deployer.getBalance()
    })
})