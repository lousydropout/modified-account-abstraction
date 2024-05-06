// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

/// Instances of this contract are meant to be used as smart contract accounts.
/// As such, an instance is to be deployed for each user who wants to use it.
contract SmartAccount {
    address public owner;

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }

    /// To change the owner of the contract for
    /// 1. when user wants to take ownership of the smart account or
    /// 2. when the owner wants to transfer the ownership to another address
    function changeOwner(address _newOwner) public onlyOwner {
        owner = _newOwner;
    }

    /// To call any function of any contract
    function call(address _contractAddress, bytes memory _data) public payable onlyOwner {
        (bool success,) = _contractAddress.call{value: msg.value}(_data);
        require(success, "Call failed.");
    }
}
