require("@nomicfoundation/hardhat-toolbox");
require("dotenv").config();

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  solidity: "0.8.24",
  defaultNetwork: "moonbase",
  networks: {
    moonbase: {
      url: "https://moonbase-alpha.public.blastapi.io", // RPC URL for Moonbase Alpha
      accounts: [`0x${process.env.PRIVATE_KEY}`], // Your private key
      chainId: 1287, // Chain ID for Moonbase Alpha
    },
  },
};
