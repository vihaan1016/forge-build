// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

contract Ledger {
    // -- MAPPING--
    mapping(address => uint256) public balance;

    // -- EVENTS--
    event Deposit(address indexed user, uint256 amount);
    event Withdraw(address indexed user, uint256 amount);

    // -- FUNCTIONS--
    function deposit(uint256 _amount, address _receiver) public payable {
        require(msg.value == _amount, "Invalid amount");
        balance[msg.sender] -= _amount;
        balance[_receiver] += _amount;
        emit Deposit(_receiver, _amount);
    }

    function withdraw(uint256 _amount) public {
        require(balance[msg.sender] >= _amount, "Insufficient balance");
        balance[msg.sender] -= _amount;
        emit Withdraw(msg.sender, _amount);
    }
    function getYourDeposit(address user) public view returns (uint256) {
        return balance[user];
    }
}
