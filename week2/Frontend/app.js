// Contract address on sepolia
const CONTRACT_ADDRESS = "0x81D69c9240B80Ce0CAD7dd78bB6f17C8c6166cFd";

// Contract ABI
const CONTRACT_ABI = [
    "function deposit(uint256 _amount) public",
    "function transfer(uint256 _amount, address _receiver) public",
    "function withdraw(uint256 _amount) public",
    "function getBalance(address user) public view returns (uint256)",
    "function claimInitialBalance() public",
    "function hasReceivedInitial(address) public view returns (bool)",
    "event InitialBalanceGiven(address indexed user, uint256 amount)",
    "event Deposit(address indexed user, uint256 amount)",
    "event Transfer(address indexed from, address indexed to, uint256 amount)"
];

// Global variables
let provider;
let signer;
let contract;
let userAddress;

// Get all elements
const connectButton = document.getElementById("connectButton");
const walletInfo = document.getElementById("walletInfo");
const depositSection = document.getElementById("depositSection");
const transferSection = document.getElementById("transferSection");
const withdrawSection = document.getElementById("withdrawSection");
const checkSection = document.getElementById("checkSection");
const statusMessage = document.getElementById("status");

// Connect Wallet
// Use try catch for error handling (supposedly a good practice)
connectButton.onclick = async function() {
    try {
        // Connect to MetaMask
        provider = new ethers.BrowserProvider(window.ethereum);
        await provider.send("eth_requestAccounts", []);
        signer = await provider.getSigner();
        userAddress = await signer.getAddress();

        // Check network
        const network = await provider.getNetwork();
        console.log("Connected to network:", network.name, "Chain ID:", network.chainId.toString());
        
        // Sepolia chainId is 11155111
        // Given by AI to directly switch to Sepolia
        if (network.chainId !== 11155111n) {
            showStatus(`Wrong network! You're on chainId ${network.chainId}. Please switch to Sepolia (chainId 11155111)`);
            
            // Try to switch to Sepolia automatically
            try {
                await window.ethereum.request({
                    method: 'wallet_switchEthereumChain',
                    params: [{ chainId: '0xaa36a7' }], // Sepolia chainId in hex
                });
                // Reload page after switching
                window.location.reload();
            } catch (switchError) {
                if (switchError.code === 4902) {
                    showStatus("Sepolia network not found in MetaMask. Please add it manually.");
                }
            }
            return;
        }

        // Verify contract address
        if (CONTRACT_ADDRESS !== "0x81D69c9240B80Ce0CAD7dd78bB6f17C8c6166cFd") {
            showStatus("Please update CONTRACT_ADDRESS in app.js!");
            return;
        }

        // Create contract instance
        contract = new ethers.Contract(CONTRACT_ADDRESS, CONTRACT_ABI, signer);

        // Get user balance
        const balance = await contract.getBalance(userAddress);
        const balanceInEth = ethers.formatEther(balance);
        
        // Check if user has claimed initial balance
        const hasClaimed = await contract.hasReceivedInitial(userAddress);
        
        // Auto-claim if they haven't received initial balance yet
        if (!hasClaimed) {
            showStatus("Claiming your initial 1000 ETH tokens...");
            const claimTx = await contract.claimInitialBalance();
            await claimTx.wait();
            
            const newBalance = await contract.getBalance(userAddress);
            const newBalanceInEth = ethers.formatEther(newBalance);
            document.getElementById("userBalance").textContent = newBalanceInEth;
            showStatus("Welcome! You received 1000 ETH tokens!");
        } else {
            document.getElementById("userBalance").textContent = balanceInEth;
        }
        
        // Show wallet info
        document.getElementById("userAddress").textContent = userAddress;
        
        // Show all sections
        // Once the user is connected, show all sections
        walletInfo.classList.remove("hidden");
        depositSection.classList.remove("hidden");
        transferSection.classList.remove("hidden");
        withdrawSection.classList.remove("hidden");
        checkSection.classList.remove("hidden");

        // Update button
        connectButton.textContent = "Connected";
        connectButton.disabled = true;

        showStatus("Connected successfully!");

    } catch (error) {
        console.error(error);
        showStatus("Error: " + error.message);
    }
};

// Deposit Button
document.getElementById("depositButton").onclick = async function() {
    try {
        const amount = document.getElementById("depositAmount").value;
        
        if (!amount || amount <= 0) {
            showStatus("Please enter a valid amount");
            return;
        }

        showStatus("Adding tokens to your balance...");

        const tx = await contract.deposit(ethers.parseEther(amount));

        showStatus("Waiting for confirmation...");
        await tx.wait();

        // Update balance
        const balance = await contract.getBalance(userAddress);
        const balanceInEth = ethers.formatEther(balance);
        document.getElementById("userBalance").textContent = balanceInEth;

        showStatus(`Successfully deposited ${amount} ETH tokens! New balance: ${balanceInEth} ETH`);
        document.getElementById("depositAmount").value = "";

    } catch (error) {
        console.error(error);
        showStatus("Error: " + error.message);
    }
};

// Transfer Button
document.getElementById("transferButton").onclick = async function() {
    try {
        const to = document.getElementById("transferTo").value;
        const amount = document.getElementById("transferAmount").value;

        if (!to || !amount) {
            showStatus("Please fill all fields");
            return;
        }

        showStatus("Sending transfer...");

        // Send transfer transaction
        const tx = await contract.transfer(
            ethers.parseEther(amount),
            to
        );

        showStatus("Waiting for confirmation...");
        await tx.wait();

        // Update balance
        const balance = await contract.getBalance(userAddress);
        const balanceInEth = ethers.formatEther(balance);
        document.getElementById("userBalance").textContent = balanceInEth;

        showStatus(`Transfer successful! New balance: ${balanceInEth} ETH`);
        document.getElementById("transferTo").value = "";
        document.getElementById("transferAmount").value = "";

    } catch (error) {
        console.error(error);
        showStatus("Error: " + error.message);
    }
};

// Check Balance Button
document.getElementById("checkButton").onclick = async function() {
    try {
        const address = document.getElementById("checkAddress").value;

        if (!address) {
            showStatus("Please enter an address");
            return;
        }

        // Get balance
        const balance = await contract.getBalance(address);
        const balanceInEth = ethers.formatEther(balance);

        document.getElementById("checkResult").textContent = 
            "Balance: " + balanceInEth + " ETH";
        showStatus("Balance fetched successfully!");

    } catch (error) {
        console.error(error);
        showStatus("Error: " + error.message);
    }
};

// Withdraw Button
document.getElementById("withdrawButton").onclick = async function() {
    try {
        const amount = document.getElementById("withdrawAmount").value;

        if (!amount || amount <= 0) {
            showStatus("Please enter a valid amount");
            return;
        }

        showStatus("Withdrawing tokens...");

        // Withdraw tokens
        const tx = await contract.withdraw(ethers.parseEther(amount));

        showStatus("Waiting for confirmation...");
        await tx.wait();

        // Update balance
        const balance = await contract.getBalance(userAddress);
        const balanceInEth = ethers.formatEther(balance);
        document.getElementById("userBalance").textContent = balanceInEth;

        showStatus(`Successfully withdrew ${amount} ETH tokens! New balance: ${balanceInEth} ETH`);
        document.getElementById("withdrawAmount").value = "";
    } catch (error) {
        console.error(error);
        showStatus("Error: " + error.message);
    }
};

// Helper function to show status
// Added by AI for better user feedback
function showStatus(message) {
    statusMessage.textContent = message;
    statusMessage.style.backgroundColor = "#fff3cd";
    statusMessage.style.color = "#856404";
}