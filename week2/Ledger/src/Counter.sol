// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

contract Ledger {
    // -- MAPPING--
    mapping(address => uint256) public balance;
    mapping(address => bool) public hasReceivedInitial;

    // -- EVENTS--
    event Deposit(address indexed user, uint256 amount);
    event Withdraw(address indexed user, uint256 amount);
    event InitialBalanceGiven(address indexed user, uint256 amount);

    // -- CONSTANTS--
    uint256 public constant INITIAL_BALANCE = 1000 ether;

    // --MODIFIERS--
    // Modifier to automatically give initial balance
    // Used to avoid repeated code in deposit and transfer functions
    modifier giveInitialBalance() {
        if (!hasReceivedInitial[msg.sender]) {
            balance[msg.sender] = INITIAL_BALANCE;
            hasReceivedInitial[msg.sender] = true;
            emit InitialBalanceGiven(msg.sender, INITIAL_BALANCE);
        }
        _;
    }

    // -- FUNCTIONS--
    function deposit() public payable giveInitialBalance {
        balance[msg.sender] += msg.value;
        emit Deposit(msg.sender, msg.value);
    }
    
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
    }
    
    function getBalance(address user) public view returns (uint256) {
        return balance[user];
    }
    
    // Function to claim initial balance manually
    function claimInitialBalance() public {
        require(!hasReceivedInitial[msg.sender], "Already claimed");
        balance[msg.sender] = INITIAL_BALANCE;
        hasReceivedInitial[msg.sender] = true;
        emit InitialBalanceGiven(msg.sender, INITIAL_BALANCE);
    }
}