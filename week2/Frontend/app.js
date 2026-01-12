// Contract address deployed on Sepolia
const CONTRACT_ADDRESS = "0x117aEeAD6F30e9fEbEA4b6BF8477B722F5A4d970";

// Contract ABI
const CONTRACT_ABI = [
    "function deposit() public payable",
    "function transfer(uint256 _amount, address _receiver) public",
    "function getBalance(address user) public view returns (uint256)",
    "function claimInitialBalance() public",
    "function hasReceivedInitial(address) public view returns (bool)",
    "event InitialBalanceGiven(address indexed user, uint256 amount)"
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
const checkSection = document.getElementById("checkSection");
const status = document.getElementById("status");

// Connect Wallet
connectButton.onclick = async function() {
    
        // Check if MetaMask is installed
        if (!window.ethereum) {
            showStatus("Please install MetaMask!");
            return;
        }

        // Connect to MetaMask
        provider = new ethers.BrowserProvider(window.ethereum);
        await provider.send("eth_requestAccounts", []);
        signer = await provider.getSigner();
        userAddress = await signer.getAddress();

        // Check network
        const network = await provider.getNetwork();
        console.log("Connected to network:", network.name, "Chain ID:", network.chainId.toString());
        
        // Sepolia chainId is 11155111
        // Added by AI while debugging chainId comparison
        // Adds the switch to Sepolia functionality if on wrong network
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

        // Create contract instance
        contract = new ethers.Contract(CONTRACT_ADDRESS, CONTRACT_ABI, signer);

        // Get user balance
        const balance = await contract.getBalance(userAddress);
        const balanceInEth = ethers.formatEther(balance);

        // Check if user has claimed initial balance
        const hasClaimed = await contract.hasReceivedInitial(userAddress);
        
        // If not claimed or balance is 0, automatically claim
        // If already claimed, then just show balance
        if (!hasClaimed || balance === 0n) {
            showStatus("Claiming your initial 1000 ETH...");
            const claimTx = await contract.claimInitialBalance();
            await claimTx.wait();
            
            const newBalance = await contract.getBalance(userAddress);
            const newBalanceInEth = ethers.formatEther(newBalance);
            document.getElementById("userBalance").textContent = newBalanceInEth;
            showStatus("Claimed 1000 ETH successfully!");
        } else {
            document.getElementById("userBalance").textContent = balanceInEth;
        }
        
        // Show wallet info
        document.getElementById("userAddress").textContent = userAddress;
        
        // Show all sections
        walletInfo.classList.remove("hidden");
        depositSection.classList.remove("hidden");
        transferSection.classList.remove("hidden");
        checkSection.classList.remove("hidden");

        // Update button
        connectButton.textContent = "Connected";
        connectButton.disabled = true;

        showStatus("Connected successfully!");

    
};

// Deposit Button
document.getElementById("depositButton").onclick = async function() {
        const amount = document.getElementById("depositAmount").value;
        
        if (!amount) {
            showStatus("Please enter an amount");
            return;
        }

        showStatus("Sending transaction...");

        // Send deposit transaction
        const tx = await contract.deposit({
            value: ethers.parseEther(amount)
        });

        showStatus("Waiting for confirmation...");
        await tx.wait();

        // Update balance
        const balance = await contract.getBalance(userAddress);
        const balanceInEth = ethers.formatEther(balance);
        document.getElementById("userBalance").textContent = balanceInEth;

        showStatus("Deposit successful!");
        document.getElementById("depositAmount").value = "";

};

// Transfer Button
document.getElementById("transferButton").onclick = async function() {
        const to = document.getElementById("transferTo").value;
        const amount = document.getElementById("transferAmount").value;

        if (!to || !amount) {
            showStatus("Please fill all fields");
            return;
        }

        showStatus("Sending transaction...");

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

        showStatus("Transfer successful!");
        document.getElementById("transferTo").value = "";
        document.getElementById("transferAmount").value = "";

};

// Check Balance Button
document.getElementById("checkButton").onclick = async function() {
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
};

// Helper function to show status
function showStatus(message) {
    status.textContent = message;
    status.style.backgroundColor = "#fff3cd";
    status.style.color = "#856404";
}