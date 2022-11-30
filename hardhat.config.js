require("@nomicfoundation/hardhat-toolbox");
require('@nomiclabs/hardhat-etherscan')
require("hardhat-contract-sizer");
require("hardhat-gas-reporter");
require("solidity-coverage")
require("dotenv/config")

module.exports = {
  solidity: {
    version: "0.8.15",
    settings: {
      optimizer: {
        enabled: true,
        runs: 200,
      },
    },
  },
  contractSizer: {
    alphaSort: false,
    disambiguatePaths: false,
    runOnCompile: true,
    strict: false,
    only: [""],
  },
  gasReporter: {
    currency: "CHF",
    gasPrice: 21,
    enabled: true,
  },
  networks: {
    // forking: {
    //   url: "https://goerli.infura.io/v3/9aa3d95b3bc440fa88ea12eaa4456161",
    // },
    goerli: {
      url: process.env.GOERLI,
      saveDeployments: true,
      accounts:
        process.env.PRIVATE_KEY !== undefined ? [process.env.PRIVATE_KEY] : [],
    },
    local: {
      url: "http://127.0.0.1:8545", // Coverage launches its own ganache-cli client
    },
  },
  etherscan: {
    apiKey: process.env.ETHERSCAN_API_KEY
 }
};
