import * as dotenv from "dotenv";
dotenv.config();
import { HardhatUserConfig } from "hardhat/config";
import "@nomicfoundation/hardhat-toolbox";
import "@nomicfoundation/hardhat-foundry";
import "@nomicfoundation/hardhat-verify";
const gasLimit = 60000000;

const config: HardhatUserConfig = {
  solidity: {
    version: "0.8.24",
    settings: {
      outputSelection: {
        "*": {
          "*": ["storageLayout"],
        },
      },
      optimizer: {
        enabled: true,
        runs: 10,
      },
    },
  },
  networks: {
    sepolia: {
      url: process.env.SEPOLIA_RPC_URL!,
      accounts: [process.env.DEPLOYER_PRIVATE_KEY!],
      blockGasLimit: gasLimit,
    },
    polygonMumbai: {
      url: process.env.POLYGON_MUMBAI_RPC_URL!,
      accounts: [process.env.DEPLOYER_PRIVATE_KEY!],
      blockGasLimit: gasLimit,
    },
    polygon: {
      url: process.env.POLYGON_POS_RPC_URL!,
      accounts: [process.env.DEPLOYER_PRIVATE_KEY!],
      // blockGasLimit: gasLimit,
    },
    opSepolia: {
      url: process.env.OPTIMISM_SEPOLIA_RPC_URL!,
      accounts: [process.env.DEPLOYER_PRIVATE_KEY!],
      blockGasLimit: gasLimit,
    },
  },
  etherscan: {
    apiKey: {
      sepolia: process.env.API_KEY_ETHERSCAN!,
      polygonMumbai: process.env.API_KEY_POLYGONSCAN!,
      polygon: process.env.API_KEY_POLYGONSCAN!,
      opSepolia: process.env.API_KEY_OPTIMISTIC_ETHERSCAN!,
    },
  },
};

export default config;
