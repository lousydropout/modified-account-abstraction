import express from "express";
import hre from "hardhat";
import "dotenv/config";

// get and log owner account
const [owner] = await hre.ethers.getSigners();
console.log("owner:", owner.address);

// smart contract accounts
// username -> user's smart account's address
const accounts = {};

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

// middleware
const logger = (req, res, next) => {
  console.log(`Request '${req.method} ${req.url}' received!`);
  console.log("body: ", req.body);
  console.log("path params: ", req.params);
  console.log("query params: ", req.query);
  next();
};

// express app
const app = express();
app.use(express.json());
app.use(express.urlencoded({ extended: true }));
app.use(logger);

// Note: For most of the endpoints below, you'd probably wanna protect
//    them with some kind of authentication. However, for the sake of
//    simplicity, we're not doing that here.

// GET /config/contracts/:contractAddress/users/:username
app.get(
  "/config/contracts/:contractAddress/users/:username",
  async (req, res) => {
    try {
      let { username, contractAddress } = req.params;
      username = username.toLowerCase();
      console.log("username:", username, typeof username);
      console.log("contractAddress:", contractAddress, typeof contractAddress);

      // get user account
      const userAccount = await configuration.getUserAccount(
        username,
        contractAddress
      );
      console.log("userAccount:", userAccount, typeof userAccount);

      // return user account address
      res.json({ userAccount });
    } catch (error) {
      res.status(400).json({ error: error.message });
    }
  }
);

// POST /config/user
app.post("/config/users", async (req, res) => {
  try {
    let userAccount;
    let { username, contractAddress } = req.body;
    username = username.toLowerCase();

    // check cache for user account
    userAccount = accounts[username];
    if (userAccount !== "0x0000000000000000000000000000000000000000") {
      res.json({ message: "User account already exists.", userAccount });
    }

    // check configuration contract for user account
    userAccount = await configuration
      .connect(owner)
      .getUserAccount(username, contractAddress);
    if (userAccount !== "0x0000000000000000000000000000000000000000") {
      res.json({ message: "User account already exists.", userAccount });
    }

    // deploy new smart account for user
    userAccount = await Account.deploy();
    await userAccount.waitForDeployment();

    // set user account in configuration contract
    configuration
      .connect(owner)
      .addUser(username, contractAddress, userAccount.target);

    // cache user account
    accounts[username] = userAccount.target;

    // return user account address
    res.status(201).json({
      message: "User account created.",
      userAccount: userAccount.target,
    });
  } catch (error) {
    res.status(400).json({ error: error.message });
  }
});

// POST /proxy/call
app.post("/proxy/call", async (req, res) => {
  try {
    let { username, contractAddress, txData } = req.body;
    console.log("{ username, contractAddress, txData }: ", {
      username,
      contractAddress,
      txData,
    });
    username = username.toLowerCase();

    let userAccount = accounts[username];
    console.log("userAccount:", userAccount);
    if (!userAccount) {
      // check configuration contract for account address
      userAccount = await configuration
        .connect(owner)
        .getUserAccount(username, contractAddress);

      console.log("userAccount:", userAccount);

      // if account address is not found, throw an error
      if (userAccount === "0x0000000000000000000000000000000000000000") {
        throw new Error("User account not found.");
      }

      // if account address is found, cache it
      accounts[username] = userAccount;
    }

    // have `user` call contract at `contractAddress` with `txData`
    const user = Account.attach(userAccount);
    const x = await user.connect(owner).call(contractAddress, txData);
    console.log("x:", x);

    res.send();
  } catch (error) {
    console.error(error);
    res.status(400).json({ error: error.message });
  }
});

// start server
app.listen(3000);
