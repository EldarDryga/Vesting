const { BigNumber } = require("ethers");
const { expect } = require("chai")
const hre = require("hardhat");
const ethers = hre.ethers
async function main() {
  
   
    const [signer] = await ethers.getSigners()
    const DniproToken = await ethers.getContractFactory("DPT");
    DPT = await DniproToken.deploy("DniproToken", "DPT", BigNumber.from("1000000000000").mul(BigNumber.from("10").pow(18)));
    await DPT.deployed()
    const Vesting = await ethers.getContractFactory("Vesting", signer)
    
    vesting = await Vesting.deploy(DPT.address)
    await DPT.deployed()
    console.log("DPT address - ", DPT.address)
    console.log("Vesting address - ", vesting.address)


}


main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
