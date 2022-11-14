const {
  time,
  loadFixture,
} = require("@nomicfoundation/hardhat-network-helpers");
const hre = require("hardhat")
const { anyValue } = require("@nomicfoundation/hardhat-chai-matchers/withArgs");
const { expect } = require("chai");
const ManagerDeploy = require("./deploy/mananger");
const { ethers } = require("hardhat");

// contract("Factory",async(accounts)=>{
// console.log(accounts)
// })

describe("Platform Manager", function (accounts) {
  let Manager;
  let ManagerAddr;
  let Signers;

  beforeEach(async () => {
    Manager = await ManagerDeploy();
    ManagerAddr = Manager.address;
    Signers = await ethers.getSigners()
  });

  it("Should set the right unlockTime", async function () {
    console.log("测试打印一下", ManagerAddr);
  });

  //   describe("Withdrawals", function () {
  //     describe("Validations", function () {
  //       it("Should revert with the right error if called too soon", async function () {
  //         const { lock } = await loadFixture(deployOneYearLockFixture);

  //         await expect(lock.withdraw()).to.be.revertedWith(
  //           "You can't withdraw yet"
  //         );
  //       });

  //       it("Should revert with the right error if called from another account", async function () {
  //         const { lock, unlockTime, otherAccount } = await loadFixture(
  //           deployOneYearLockFixture
  //         );

  //         // We can increase the time in Hardhat Network
  //         await time.increaseTo(unlockTime);

  //         // We use lock.connect() to send a transaction from another account
  //         await expect(lock.connect(otherAccount).withdraw()).to.be.revertedWith(
  //           "You aren't the owner"
  //         );
  //       });

  //       it("Shouldn't fail if the unlockTime has arrived and the owner calls it", async function () {
  //         const { lock, unlockTime } = await loadFixture(
  //           deployOneYearLockFixture
  //         );

  //         // Transactions are sent using the first signer by default
  //         await time.increaseTo(unlockTime);

  //         await expect(lock.withdraw()).not.to.be.reverted;
  //       });
  //     });

  //     describe("Events", function () {
  //       it("Should emit an event on withdrawals", async function () {
  //         const { lock, unlockTime, lockedAmount } = await loadFixture(
  //           deployOneYearLockFixture
  //         );

  //         await time.increaseTo(unlockTime);

  //         await expect(lock.withdraw())
  //           .to.emit(lock, "Withdrawal")
  //           .withArgs(lockedAmount, anyValue); // We accept any value as `when` arg
  //       });
  //     });

  //     describe("Transfers", function () {
  //       it("Should transfer the funds to the owner", async function () {
  //         const { lock, unlockTime, lockedAmount, owner } = await loadFixture(
  //           deployOneYearLockFixture
  //         );

  //         await time.increaseTo(unlockTime);

  //         await expect(lock.withdraw()).to.changeEtherBalances(
  //           [owner, lock],
  //           [lockedAmount, -lockedAmount]
  //         );
  //       });
  //     });
  //   });
});
