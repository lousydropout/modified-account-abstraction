// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

contract FavoriteColor {
    mapping(address => string) public favoriteColor;

    constructor() {}

    function setFavoriteColor(string memory color) public {
        favoriteColor[msg.sender] = color;
    }

    function getFavoriteColor() public view returns (string memory) {
        return favoriteColor[msg.sender];
    }

    function getFavoriteColorOfUser(address _user) public view returns (string memory) {
        return favoriteColor[_user];
    }
}
