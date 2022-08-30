const { expect } = require("chai")
const { ethers } = require("hardhat")
const { BigNumber } = require("ethers");

describe.only("Vesting", function () {
    let owner
    let acc2
    let acc3
    let acc4
    let vesting
    let vesting2
    let DPT
    beforeEach(async function () {
        const DniproToken = await ethers.getContractFactory("DPT");
        DPT = await DniproToken.deploy("DniproToken", "DPT", BigNumber.from("100000000").mul(BigNumber.from("10").pow(18)));
        [owner, acc2, acc3, acc4] = await ethers.getSigners()
        const Vesting = await ethers.getContractFactory("Vesting", owner)
        vesting = await Vesting.deploy(DPT.address)
    })
    it("Address should have 0 address", async function(){
        let zero_address = "0x0000000000000000000000000000000000000000"
        const Vesting = await ethers.getContractFactory("Vesting", owner)
       await expect(Vesting.deploy(zero_address)).to.be.revertedWith("Address of token = 0")
        })
    it("Vesting started successfully!", async function () {
        const amountOfDistribution = 10000;
        const periodOfDistributionInDays = 7;
        const amountOfDistributionPerUser = 100;
        await DPT.approve(vesting.address, amountOfDistribution)
        await expect(vesting.connect(acc2).claimRevard()).to.be.revertedWith("Vesting has not started");
        await expect(vesting.connect(acc2).join()).to.be.revertedWith("Vesting has not started");
        await expect(vesting.connect(acc2).startVesting(amountOfDistribution, periodOfDistributionInDays, amountOfDistributionPerUser)).to.be.revertedWith("Ownable: caller is not the owner")
        await vesting.connect(owner).startVesting(amountOfDistribution, periodOfDistributionInDays, amountOfDistributionPerUser)
        await expect(vesting.connect(acc2).claimRevard()).to.be.revertedWith("You have not joined the vesting");
        expect(await DPT.balanceOf(vesting.address)).to.eq(10000)
        expect(await vesting.maxUsers()).to.eq(100)
        await vesting.connect(acc2).join()
        expect(await vesting.users()).to.eq(1)
    })
    it("users joined vesting succesfully", async function () {
        const amountOfDistribution = 1000;
        const periodOfDistributionInDays = 5;
        const amountOfDistributionPerUser = 500;
        await DPT.approve(vesting.address, amountOfDistribution)
        await vesting.connect(owner).startVesting(amountOfDistribution, periodOfDistributionInDays, amountOfDistributionPerUser)
        await vesting.connect(acc2).join()
        await vesting.connect(acc3).join()
        await expect(vesting.connect(acc2).join()).to.be.revertedWith("You have already started vesting, use claimRevard to receive your revard")
        await expect(vesting.connect(acc4).join()).to.be.revertedWith("Unfortunately, the tokens for distribution have already been distributed, or are distributing to the remaining users")
    })
    it("users started to receive tokens successfully", async function () {
        const amountOfDistribution = 10000;
        const periodOfDistributionInDays = 10;
        const amountOfDistributionPerUser = 1000;
        await DPT.approve(vesting.address, amountOfDistribution)
        await vesting.connect(owner).startVesting(amountOfDistribution, periodOfDistributionInDays, amountOfDistributionPerUser)

        await vesting.connect(acc3).join()
        const fiveDays = 5 * 24 * 60 * 60;
        const blockNumBefore = await ethers.provider.getBlockNumber();
        const blockBefore = await ethers.provider.getBlock(blockNumBefore);
        const timestampBefore = blockBefore.timestamp;
        await ethers.provider.send('evm_mine', [timestampBefore + fiveDays]);
        await vesting.connect(acc3).claimRevard()
       
        expect(await DPT.balanceOf(vesting.address)).to.eq(9501)
        expect(await DPT.balanceOf(acc3.address)).to.eq(499)

        await vesting.connect(acc4).join()
        const tenDays = 10 * 24 * 60 * 60;
        await ethers.provider.send('evm_mine', [timestampBefore + tenDays]);
        expect( await vesting.connect(acc3).showRevardToClaim()).to.eq(501)
        expect( await vesting.connect(acc4).showRevardToClaim()).to.eq(499)

        await vesting.connect(acc3).claimRevard()
        await vesting.connect(acc4).claimRevard()
        expect(await DPT.balanceOf(vesting.address)).to.eq(8501)
        expect(await DPT.balanceOf(acc3.address)).to.eq(1000)
        expect(await DPT.balanceOf(acc4.address)).to.eq(499)
        await expect(vesting.connect(acc3).claimRevard()).to.be.revertedWith("You have received all tokens");

        await expect(vesting.connect(acc3).stopVesting()).to.be.revertedWith("Ownable: caller is not the owner")
        await vesting.connect(owner).stopVesting()
        await expect(vesting.connect(acc2).claimRevard()).to.be.revertedWith("Vesting has not started");
    })
})
































