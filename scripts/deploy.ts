import { Contract } from "@ethersproject/contracts";
// We require the Hardhat Runtime Environment explicitly here. This is optional but useful for running the
// script in a standalone fashion through `node <script>`. When running the script with `hardhat run <script>`,
// you'll find the Hardhat Runtime Environment's members available in the global scope.
import { ethers } from "hardhat";

async function main(): Promise<void> {
  const [deployer] = await ethers.getSigners();

  console.log("Account balance:", (await deployer.getBalance()).toString());

  const floatiesFactory = await ethers.getContractFactory("FloatiesLongShortPairFinancialProductLibrary");
  const floaties = await floatiesFactory.deploy();

  await floaties.deployed();

  console.log("Floaties deployed to:", floaties.address);
}

// We recommend this pattern to be able to use async/await everywhere and properly handle errors.
main()
  .then(() => process.exit(0))
  .catch((error: Error) => {
    console.error(error);
    process.exit(1);
  });
