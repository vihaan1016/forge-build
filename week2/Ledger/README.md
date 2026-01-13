# Ledger DApp

## Features

- **Wallet Connection**: Connect your MetaMask wallet to interact with the DApp
- **Initial Balance**: Automatically receive 1000 ETH on first use
- **Deposit**: Add ETH to your contract balance
- **Transfer**: Send ETH to other addresses
- **Balance Checking**: View the balance of any address

## Smart Contract

**Contract Address (Sepolia)**: `0x81D69c9240B80Ce0CAD7dd78bB6f17C8c6166cFd`

### Contract Functions

- `deposit()`: Deposit ETH into your balance
- `transfer(uint256 _amount, address _receiver)`: Transfer tokens to another address
- `getBalance(address user)`: View balance of any address
- `claimInitialBalance()`: Manually claim your initial 1000 ETH
- `hasReceivedInitial(address)`: Check if an address has claimed their initial balance

### Contract Features

- Users automatically receive 1000 ETH on first interaction
- Both sender and receiver get initial balance when needed
- Balance tracking via mapping
- Event emissions for deposits and initial balance claims


## Prerequisites

- [MetaMask](https://metamask.io/) browser extension
- Sepolia testnet ETH (get from [faucet](https://sepoliafaucet.com/))
- Modern web browser
- [Foundry](https://book.getfoundry.sh/) (for contract development/testing)

## Setup & Usage

### Frontend

1. Clone the repository
2. Open `index.html` in a web browser (or serve via a local server)
3. Click "Connect MetaMask"
4. Ensure you're on the Sepolia testnet (the app will prompt you to switch if needed)
5. Your initial 1000 ETH will be automatically claimed
6. Start depositing and transferring!

### Smart Contract Development

The contract is built using Foundry. To test:

```bash
forge test
```

To deploy:

```bash
forge create --rpc-url <SEPOLIA_RPC_URL> \
  --private-key <YOUR_PRIVATE_KEY> \
  src/Counter.sol:Ledger
```

## Testing

The project includes two test cases in `Counter.t.sol`:

- `test_Transfer()`: Verifies successful transfer between addresses
- `test_Transfer_InsufficientBalance()`: Ensures transfers fail when balance is insufficient

Run tests with:
```bash
forge test -vv
```

## Network Handling

The DApp automatically detects if you're on the wrong network and will:
1. Alert you that you need to be on Sepolia
2. Attempt to switch your MetaMask to Sepolia automatically
3. Reload the page after successful network switch

