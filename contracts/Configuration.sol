// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

contract Configuration {
    address public owner;
    // e.g. pricing[devUsername][contractAddress] = "500/10"
    //      to mean 500 txs for $10.00
    mapping(string => mapping(address => string)) public pricing;

    // e.g. renainingTxs[username][contractAddress] = 500
    mapping(string => mapping(address => uint256)) public renainingTxs;

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }

    function changeOwner(address _newOwner) public onlyOwner {
        owner = _newOwner;
    }

    function decrement(string memory _username, address _contractAddress) public onlyOwner returns (bool) {
        if (renainingTxs[_username][_contractAddress] == 0) {
            return false;
        }

        // all arithmetic is checked for underflow in Solidity 0.8.0 and later
        renainingTxs[_username][_contractAddress]--;
        return true;
    }

    function getPricing(string memory _dev, address _contractAddress) public view returns (string memory) {
        return pricing[_dev][_contractAddress];
    }

    function getRemainingTxs(string memory _username, address _contractAddress) public view returns (uint256) {
        return renainingTxs[_username][_contractAddress];
    }
}
