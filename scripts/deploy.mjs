// npx hardhat run scripts/deploy.mjs
import hre from "hardhat";
import { appendToEnv } from "./append.mjs";

async function main() {
  const [owner] = await hre.ethers.getSigners();
  console.log("owner:", owner.address);

  // deploy the `FavoriteColor` smart contract
  const FavoriteColor = await hre.ethers.getContractFactory("FavoriteColor");
  const favoriteColor = await FavoriteColor.deploy();
  await favoriteColor.waitForDeployment();

  console.log("contract FavoriteColor deployed to:", favoriteColor.target);
  appendToEnv("FAVORITE_COLOR", favoriteColor.target);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
