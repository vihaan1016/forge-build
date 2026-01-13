// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

contract Ledger {
    // -- MAPPING--
    mapping(address => uint256) public balance;
    mapping(address => bool) public hasReceivedInitial;

    // -- EVENTS--
    event Deposit(address indexed user, uint256 amount);
    event Transfer(address indexed from, address indexed to, uint256 amount);
    event InitialBalanceGiven(address indexed user, uint256 amount);

    // -- CONSTANTS--
    uint256 public constant INITIAL_BALANCE = 1000 ether;

    // --MODIFIERS--
    modifier giveInitialBalance() {
        if (!hasReceivedInitial[msg.sender]) {
            balance[msg.sender] = INITIAL_BALANCE;
            hasReceivedInitial[msg.sender] = true;
            emit InitialBalanceGiven(msg.sender, INITIAL_BALANCE);
        }
        _;
    }

    // -- FUNCTIONS--
    
    // Deposit fake ETH tokens to increase balance
    function deposit(uint256 _amount) public giveInitialBalance {
        balance[msg.sender] += _amount;
        emit Deposit(msg.sender, _amount);
    }
    
    // Transfer tokens between users
    function transfer(uint256 _amount, address _receiver) public giveInitialBalance {
        require(balance[msg.sender] >= _amount, "Insufficient balance");
        balance[msg.sender] -= _amount;
        
        // Give initial balance to receiver if they haven't received it
        if (!hasReceivedInitial[_receiver]) {
            balance[_receiver] = INITIAL_BALANCE;
            hasReceivedInitial[_receiver] = true;
            emit InitialBalanceGiven(_receiver, INITIAL_BALANCE);
        }
        
        balance[_receiver] += _amount;
        emit Transfer(msg.sender, _receiver, _amount);
    }
    
    // Withdraw tokens (reduce balance)
    function withdraw(uint256 _amount) public {
        require(balance[msg.sender] >= _amount, "Insufficient balance");
        balance[msg.sender] -= _amount;
    }
    
    function getBalance(address user) public view returns (uint256) {
        return balance[user];
    }
    
    // Claim initial 1000 ETH tokens
    function claimInitialBalance() public {
        require(!hasReceivedInitial[msg.sender], "Already claimed");
        balance[msg.sender] = INITIAL_BALANCE;
        hasReceivedInitial[msg.sender] = true;
        emit InitialBalanceGiven(msg.sender, INITIAL_BALANCE);
    }
}