import hre from "hardhat";
import "dotenv/config";

const baseUrl = "http://localhost:3000";

// smart contract addresses
const FAVORITE_COLOR_ADDRESS = process.env.FAVORITE_COLOR;
const COUNTER_ADDRESS = process.env.COUNTER;
const CONFIGURATION_ADDRESS = process.env.CONFIGURATION;

// smart contracts
const Account = await hre.ethers.getContractFactory("SmartAccount");

const Configuration = await hre.ethers.getContractFactory("Configuration");
const configuration = Configuration.attach(CONFIGURATION_ADDRESS);

const FavoriteColor = await hre.ethers.getContractFactory("FavoriteColor");
const favoriteColor = FavoriteColor.attach(FAVORITE_COLOR_ADDRESS);

const Counter = await hre.ethers.getContractFactory("Counter");
const counter = Counter.attach(COUNTER_ADDRESS);

const getUserAccount = async (username, contractAddress) => {
  return await fetch(
    `${baseUrl}/config/contracts/${contractAddress}/users/${username}`
  );
};

const incrementCount = async (username) => {
  try {
    const tx = await counter.increment.populateTransaction();
    console.log("tx: ", tx.data);

    const body = JSON.stringify({
      username,
      contractAddress: COUNTER_ADDRESS,
      txData: tx.data,
    });
    console.log("body: ", body);

    fetch(`${baseUrl}/proxy/call`, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
      },
      body,
    });
    return true;
  } catch (error) {
    console.error(error);
    return false;
  }
};

const getCount = async (username) => {
  try {
    const response = await getUserAccount(username, COUNTER_ADDRESS);
    const { userAccount } = await response.json();
    console.log("userAccount: ", userAccount);

    return await counter.getCounterOfUser(userAccount);
  } catch (error) {
    console.error(error);
    return -1;
  }
};

// const response = await getUserAccount(
//   "Vincent",
//   "0xF4AD185A9E575b77dc671860469e41bf42782810"
// );
// console.log("response: ", response);

// const result = await response.json();
// console.log("result: ", result);

// const response = await incrementCount("vincent");
// console.log("response: ", response);

const count = await getCount("Vincent");
console.log("count: ", count);
