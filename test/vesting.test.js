const { expect } = require("chai")
const { ethers } = require("hardhat")
const { BigNumber } = require("ethers");

describe.only("Vesting", function () {
    let owner
    let acc2
    let acc3
    let acc4
    let vesting
    let DPT
    beforeEach(async function () {
        const DniproToken = await ethers.getContractFactory("DPT");
        DPT = await DniproToken.deploy("DniproToken", "DPT", BigNumber.from("100000000").mul(BigNumber.from("10").pow(18)));
        [owner, acc2, acc3, acc4] = await ethers.getSigners()
        const Vesting = await ethers.getContractFactory("Vesting", owner)
        vesting = await Vesting.deploy(DPT.address)
    })

    it("Vesting started successfully!", async function () {
        const amountOfDistribution = 10000;
        const periodOfDistributionInDays = 7;
        const amountOfDistributionPerUser = 100;
        await DPT.approve(vesting.address, amountOfDistribution)
        await expect(vesting.connect(acc2).claimRevard()).to.be.revertedWith("Vesting has not started");
        await expect(vesting.connect(acc2).join()).to.be.revertedWith("Vesting has not started");
        await vesting.connect(owner).startVesting(amountOfDistribution, periodOfDistributionInDays, amountOfDistributionPerUser)
        await expect(vesting.connect(acc2).claimRevard()).to.be.revertedWith("You have not joined the vesting");
        expect(await DPT.balanceOf(vesting.address)).to.eq(10000)
        expect(await vesting.initialized()).to.eq(true)
        expect(await vesting.maxUsers()).to.eq(100)
        await vesting.connect(acc2).join()
        expect(await vesting.users()).to.eq(1)
    })
    it("user should joined vesting", async function () {
        const amountOfDistribution = 1000000;
        const periodOfDistributionInDays = 100;
        const amountOfDistributionPerUser = 3000;
        await DPT.approve(vesting.address, amountOfDistribution)
        await vesting.connect(owner).startVesting(amountOfDistribution, periodOfDistributionInDays, amountOfDistributionPerUser)
        await vesting.connect(acc2).join()
        await vesting.connect(acc3).join()
        expect(await vesting.users()).to.eq(2)
    })
    it("users started to receive tokens successfully!", async function () {
        const amountOfDistribution = 10000;
        const periodOfDistributionInDays = 10;
        const amountOfDistributionPerUser = 1000;
        await DPT.approve(vesting.address, amountOfDistribution)
        await vesting.connect(owner).startVesting(amountOfDistribution, periodOfDistributionInDays, amountOfDistributionPerUser)

        await vesting.connect(acc3).join()
        await vesting.connect(acc3).claimRevard()
        const fiveDays = 5 * 24 * 60 * 60;
        const blockNumBefore = await ethers.provider.getBlockNumber();
        const blockBefore = await ethers.provider.getBlock(blockNumBefore);
        const timestampBefore = blockBefore.timestamp;
        await ethers.provider.send('evm_mine', [timestampBefore + fiveDays]);
        await vesting.connect(acc3).showRevardToClaim()
        await vesting.connect(acc3).claimRevard()
       
        expect(await DPT.balanceOf(vesting.address)).to.eq(9501)
        expect(await DPT.balanceOf(acc3.address)).to.eq(499)


        await vesting.connect(acc4).join()
        await vesting.connect(acc4).claimRevard()

        const tenDays = 10 * 24 * 60 * 60;
        await ethers.provider.send('evm_mine', [timestampBefore + tenDays]);
        await vesting.connect(acc3).claimRevard()
        await vesting.connect(acc4).claimRevard()
        expect(await DPT.balanceOf(vesting.address)).to.eq(8501)
        expect(await DPT.balanceOf(acc3.address)).to.eq(1000)
        expect(await DPT.balanceOf(acc4.address)).to.eq(499)

        const severalDays = 15 * 24 * 60 * 60 + 1;
        await ethers.provider.send('evm_mine', [timestampBefore + severalDays]);
        await vesting.connect(acc4).claimRevard()
        expect(await DPT.balanceOf(acc4.address)).to.eq(1000)
        expect(await DPT.balanceOf(vesting.address)).to.eq(8000)
        await expect(vesting.connect(acc3).claimRevard()).to.be.revertedWith("You have received all tokens");


        await vesting.connect(acc2).join()
        await vesting.connect(acc2).claimRevard()
        const twentyFiveDays = 25 * 24 * 60 * 60 + 3;
        await ethers.provider.send('evm_mine', [timestampBefore + twentyFiveDays]);
        await vesting.connect(acc2).claimRevard()
        expect(await DPT.balanceOf(acc2.address)).to.eq(1000)
        await DPT.approve(vesting.address, amountOfDistribution)
        await vesting.connect(owner).startVesting(amountOfDistribution, periodOfDistributionInDays, amountOfDistributionPerUser)
        await expect(vesting.connect(acc3).showRevardToClaim()).to.be.revertedWith("Time to claim all your revard")
        await vesting.connect(owner).stopVesting()
        await expect(vesting.connect(acc2).claimRevard()).to.be.revertedWith("Vesting has not started");


    })
})
































