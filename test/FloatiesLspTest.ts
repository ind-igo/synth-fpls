import { waffle, ethers, artifacts } from "hardhat";
import { Artifact } from "hardhat/types";
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/dist/src/signer-with-address";
import { MockProvider } from "@ethereum-waffle/provider";
//import { Greeter } from "../typechain/Greeter";
import { FloatiesLongShortPairFinancialProductLibrary } from "../typechain";
import { Signers } from "../types";
import { expect } from "chai";

const { deployContract } = waffle;

//const FloatiesFpl = hre.getContract("FloatiesLongShortPairFinancialProductLibrary");

describe("Floaties Tests", function () {
  const [wallet, otherWallet] = new MockProvider().getWallets();
  let accounts: Signers;
  let floaties;

  before(async function () {
    this.signers = {} as Signers;

    const signers: SignerWithAddress[] = await ethers.getSigners();
    accounts.admin = signers[0];
  });

  describe("LSP Parameterization", function () {
    beforeEach(async function () {
      const floatiesArtifact: Artifact = await artifacts.readArtifact("FloatiesLongShortPairFinancialProductLibrary");
      floaties = <FloatiesLongShortPairFinancialProductLibrary>await deployContract(wallet, floatiesArtifact);
    });

    it("Can set and fetch valid values", async function () {
      //expect(await this.floaties.connect(wallet)).to.equal("Hello, world!");
      const floatiesContract = await floaties.connect(wallet);

      await this.greeter.setGreeting("Hola, mundo!");
      expect(await this.greeter.connect(this.signers.admin).greet()).to.equal("Hola, mundo!");
    });
  });

  describe("Compute expiry prices", function () {
    beforeEach(async function () {
      return null;
    });
  });
});
