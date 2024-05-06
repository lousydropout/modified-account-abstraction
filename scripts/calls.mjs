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

    const response = await fetch(`${baseUrl}/proxy/call`, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
      },
      body,
    });
    if (!response.ok) return false; // throw new Error((await response.json()).error);

    console.log("response: ", await response.text());
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

const getRemainingTxs = async (username, contractAddress) => {
  try {
    return await configuration.getRemainingTxs(
      username.toLowerCase(),
      contractAddress
    );
  } catch (error) {
    console.error(error);
    return -1;
  }
};

const pay = async (username, contractAddress, numTx) => {
  return await fetch(`${baseUrl}/payment`, {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
    },
    body: JSON.stringify({ username, contractAddress, numTx }),
  });
};

// const response = await getUserAccount(
//   "Vincent",
//   "0xF4AD185A9E575b77dc671860469e41bf42782810"
// );
// console.log("response: ", response);

// const result = await response.json();
// console.log("result: ", result);

// incrementCount("vincent");
// incrementCount("vincent");
// incrementCount("vincent");
// incrementCount("vincent");
const response = await incrementCount("vincent");
console.log("response: ", response);

// const count = await getCount("Vincent");
// console.log("count: ", count, typeof count);

const remainingTxs = await getRemainingTxs("vincent", COUNTER_ADDRESS);
console.log("remainingTxs: ", remainingTxs, typeof remainingTxs);

// const response = await pay("vincent", COUNTER_ADDRESS, 5);
// console.log("response: ", response.json());
