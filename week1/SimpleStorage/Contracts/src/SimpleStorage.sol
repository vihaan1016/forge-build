// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;


contract SimpleStorage {
    uint256 myFavoriteNumber;

    // uint256[] public anArray;
    function set(uint256 _favoriteNumber) public {
        myFavoriteNumber = _favoriteNumber;
    }
    function get() public view returns(uint256) {
        return myFavoriteNumber;
    }   
}