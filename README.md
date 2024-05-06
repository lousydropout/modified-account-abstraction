# modified-account-abstraction

The goal for API code and the set of smart contracts in this repo is to create a modified (and simplified) version of the popular ERC-4337.

ERC-4337 makes using dApps seemless for non-web3 users.
Unfortunately, this is only temporary and largely at the expense of the developers, who have to foot the gas transaction bill for the users.
So, unless the plan is for the dApp to make money via advertisements, this cannot last.
The devs will eventually have to force the non-web3 user to choose between giving up using the dApp any further or learn to interact with the dApp via a wallet extension such as MetaMask (as well as to set up, fund, and manage the account).

Instead here, we attempt to modify ERC-4337 to make interacting with dApps no different from interacting with a regular webapp.
The idea is to allow users to prepay for using the dApp and to track the usage via an additional smart contract.

## Contracts

The contracts are located under `contracts/`.

### SmartAccount (Smart Contract Account)

This is meant to act as the user's account.
We can use the `SmartAccount.call` function to get a user's account to make a transaction.

Unlike the other smart contracts, this one is to be deployed once for each user.

### Configuration

This contract serves two purposes:

1. It keeps track of the pricing plan associated with a `dev` and the `dev`'s deployed contract's address.
2. It keeps track of how many remaining transactions a `user` can make for a given `smart contract`.

### Counter

This is some simple smart contract whose purpose is to demonstrate how this modified account abstraction idea is supposed to work.

### FavoriteColor

Like the `Counter` smart contract, this is some simple smart contract whose purpose is to demonstrate how this modified account abstraction idea is supposed to work.

## Steps

1. `npm install`
2. Compile smart contracts: `npm run compile`
3. Deploy all non-`SmartAccount` smart contracts: `npm run deploy`
   (their addresses are automatically added to `.env`)

![Image Description](/images/dev.jpg)
![Image Description](/images/user.jpg)
![Image Description](/images/user_pays.jpg)
