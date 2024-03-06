import * as dotenv from "dotenv";
dotenv.config();
import { HardhatUserConfig } from "hardhat/config";
import "@nomicfoundation/hardhat-toolbox";
import "@nomicfoundation/hardhat-foundry";
const gasLimit = 60000000;

const config: HardhatUserConfig = {
  solidity: {
    version: "0.8.24",
    settings: {
      optimizer: {
        enabled: true,
        runs: 200,
      },
    },
  },
  networks: {
    polygonMumbai: {
      url: process.env.POLYGON_MUMBAI_RPC_URL!,
      accounts: [process.env.DEPLOYER_PRIVATE_KEY!],
      blockGasLimit: gasLimit,
    },
  },
  etherscan: {
    apiKey: {
      polygonMumbai: process.env.API_KEY_POLYGONSCAN!,
    },
  },
};

export default config;
