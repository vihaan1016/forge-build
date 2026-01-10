// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

contract Ledger {
    // -- MAPPING--
    mapping(address => uint256) public balance;

    // -- EVENTS--
    event Deposit(address indexed user, uint256 amount);
    event Withdraw(address indexed user, uint256 amount);

    // -- FUNCTIONS--
    function deposit() public payable {
        balance[msg.sender] += msg.value;
        emit Deposit(msg.sender, msg.value);
    }
    function transfer(uint256 _amount, address _receiver) public {
        balance[_receiver] += _amount;
        balance[msg.sender] -= _amount;
    }
    function getBalance(address user) public view returns (uint256) {
        return balance[user];
    }
}
