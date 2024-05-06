// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

contract Counter {
    mapping(address => uint256) public counter;

    constructor() {}

    function set(uint256 value) public {
        counter[msg.sender] = value;
    }

    function increment() public {
        counter[msg.sender]++;
    }

    function decrement() public {
        counter[msg.sender]--;
    }

    function getCounter() public view returns (uint256) {
        return counter[msg.sender];
    }

    function getCounterOfUser(address _user) public view returns (uint256) {
        return counter[_user];
    }
}
