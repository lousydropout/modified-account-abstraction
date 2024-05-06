// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

contract Configuration {
    address public owner;
    // e.g. pricing[devUsername][contractAddress] = "500/10"
    //      to mean 500 txs for $10.00
    mapping(string => mapping(address => string)) public pricing;

    // e.g. remainingTxs[contractAddress][username] = 500
    mapping(address => mapping(string => uint256)) public remainingTxs;

    // e.g. userAccounts[contractAddress][username] = 0x16E4************1063Ba
    mapping(address => mapping(string => address)) public userAccounts;

    event OwnerChanged(address indexed previousOwner, address indexed newOwner);
    event UserAdded(string username, address indexed contractAddress, address indexed userAccount);

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }

    function changeOwner(address _newOwner) public onlyOwner {
        address previousOwner = owner;
        owner = _newOwner;
        emit OwnerChanged(previousOwner, _newOwner);
    }

    function addUser(string memory _username, address _contractAddress, address _userAccount) public onlyOwner {
        userAccounts[_contractAddress][_username] = _userAccount;
        emit UserAdded(_username, _contractAddress, _userAccount);
    }

    /// increment remaining transactions for a user by specified value
    function incrementBy(string memory _username, address _contractAddress, uint256 _value) public onlyOwner {
        remainingTxs[_contractAddress][_username] += _value;
    }

    /// decrement remaining transactions for a user by 1
    function decrement(string memory _username, address _contractAddress) public onlyOwner returns (bool) {
        if (remainingTxs[_contractAddress][_username] == 0) {
            return false;
        }

        // all arithmetic calculations are checked for underflow in Solidity 0.8.0 and later
        remainingTxs[_contractAddress][_username]--;
        return true;
    }

    //////////////////////////////////////////////////
    // Getters
    //////////////////////////////////////////////////

    function getRemainingTxs(string memory _username, address _contractAddress) public view returns (uint256) {
        return remainingTxs[_contractAddress][_username];
    }

    function getPricing(string memory _dev, address _contractAddress) public view returns (string memory) {
        return pricing[_dev][_contractAddress];
    }

    function getUserAccount(string memory _username, address _contractAddress) public view returns (address) {
        return userAccounts[_contractAddress][_username];
    }
}
