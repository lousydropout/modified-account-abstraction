require("@nomicfoundation/hardhat-toolbox");
require("dotenv").config();

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  solidity: "0.8.24",
  defaultNetwork: "moonbaseAlpha",
  networks: {
    moonbaseAlpha: {
      url: "https://moonbase-alpha.public.blastapi.io", // RPC URL for Moonbase Alpha
      accounts: [`0x${process.env.PRIVATE_KEY}`], // Your private key
      chainId: 1287, // Chain ID for Moonbase Alpha
    },
    avalancheTestnet: {
      url: "https://api.avax-test.network/ext/bc/C/rpc",
      accounts: [`0x${process.env.PRIVATE_KEY}`], // Your private key
      chainId: 43113, // Chain ID for Avalanche Testnet
    },
    sepolia: {
      url: "https://sepolia.infura.io/v3",
      accounts: [`0x${process.env.PRIVATE_KEY}`], // Your private key
      chainId: 11155111, // Chain ID for Ethereum Sepolia
    },
  },
};
