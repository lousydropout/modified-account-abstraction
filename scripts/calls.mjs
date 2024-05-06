import hre from "hardhat";
import "dotenv/config";

const baseUrl = "http://localhost:3000";

// smart contract addresses
export const NULL_ADDRESS = "0x0000000000000000000000000000000000000000";
export const FAVORITE_COLOR_ADDRESS = process.env.FAVORITE_COLOR;
export const COUNTER_ADDRESS = process.env.COUNTER;
export const CONFIGURATION_ADDRESS = process.env.CONFIGURATION;

// smart contracts
const Configuration = await hre.ethers.getContractFactory("Configuration");
const configuration = Configuration.attach(CONFIGURATION_ADDRESS);

const Counter = await hre.ethers.getContractFactory("Counter");
const counter = Counter.attach(COUNTER_ADDRESS);

export const getUserAccount = async (username, contractAddress) => {
  const response = await fetch(
    `${baseUrl}/config/contracts/${contractAddress}/users/${username}`
  );
  const results = await response.json();
  const { userAccount } = results;
  return userAccount;
};

export const createUserAccount = async (username, contractAddress) => {
  try {
    const response = await fetch(`${baseUrl}/config/users`, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
      },
      body: JSON.stringify({ username, contractAddress }),
    });
    if (!response.ok) return false;
    const results = await response.json();
    console.log("createUserAccount results: ", results);
    return results;
  } catch (error) {
    console.error(error);
    return false;
  }
};

export const incrementCount = async (username) => {
  try {
    const tx = await counter.increment.populateTransaction();
    const body = JSON.stringify({
      username,
      contractAddress: COUNTER_ADDRESS,
      txData: tx.data,
    });

    const response = await fetch(`${baseUrl}/proxy/call`, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
      },
      body,
    });

    if (!response.ok) return false;
    return true;
  } catch (error) {
    console.error(error);
    return false;
  }
};

export const getCount = async (username) => {
  try {
    const userAccount = await getUserAccount(username, COUNTER_ADDRESS);

    return await counter.getCounterOfUser(userAccount);
  } catch (error) {
    console.error(error);
    return -1;
  }
};

export const getRemainingTxs = async (username, contractAddress) => {
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

export const pay = async (username, contractAddress, numTx) => {
  const response = await fetch(`${baseUrl}/payment`, {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
    },
    body: JSON.stringify({ username, contractAddress, numTx }),
  });
  const { remainingTxs } = await response.json();
  return remainingTxs;
};

const username = "bob";
let remainingTxs;
let count;
let userAccount;

// 1. Check if a user account exists
console.log("\n1. Check if a user account exists");
userAccount = await getUserAccount(username, COUNTER_ADDRESS);
console.log(
  "userAccount: ",
  userAccount === NULL_ADDRESS ? "NULL" : userAccount
);

// 2. Create a new user account if it doesn't exist
console.log("\n2. Create a new user account if it doesn't exist");
if (userAccount === NULL_ADDRESS) {
  let response = await createUserAccount(username, COUNTER_ADDRESS);
  userAccount = response.userAccount;
}

// // 3. Check the number of transactions remaining for the user
// console.log("\n3. Check the number of transactions remaining for the user");
// remainingTxs = await getRemainingTxs(username, COUNTER_ADDRESS);
// console.log("remainingTxs: ", Number(remainingTxs));

// // 4. Check the counter value for the user
// console.log("\n4. Check the counter value for the user");
// count = await getCount(username);
// console.log("count: ", count);

// // 5. Attempt to increment the counter for the user.
// //    This should fail if the user's `remainingTxs` is 0
// console.log("\n5. Attempt to increment the counter for the user.");
// const success = await incrementCount(username);
// console.log("success: ", success);

// // 6. Check the counter value for the user
// console.log("\n6. Check the counter value for the user");
// count = await getCount(username);
// console.log("count: ", count);

// // 7. Check the number of transactions remaining for the user
// console.log("\n7. Check the number of transactions remaining for the user");
// remainingTxs = await getRemainingTxs(username, COUNTER_ADDRESS);
// console.log("remainingTxs: ", Number(remainingTxs));

// 8. Pay for more transactions
// console.log("\n8. Pay for more 5 transactions");
// remainingTxs = await pay(username, COUNTER_ADDRESS, 5);
// console.log("remainingTxs: ", remainingTxs);
