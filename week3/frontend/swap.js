// --Contract/token addresses--
const CONTRACT_ADDRESS = "0xE64146364C92c120d8FE3a318972Fe2803F4b1c8";
const TOKEN_A_ADDRESS = "0x53E8bf31B9061Ecd610F4D056ADDa9c298DcA64C";
const TOKEN_B_ADDRESS = "0x3fE402d564c4DA533807558114B3B2361Cbc8af3";

// -- UI Elements --
const connectBtn = document.getElementById('connectBtn');
const initialFundBtn = document.getElementById('fundBtn');
const addLiquidityBtn = document.getElementById('addLiqBtn');
const removeLiquidityBtn = document.getElementById('removeLiqBtn');
const swapAButton = document.getElementById('swapABtn');
const swapBButton = document.getElementById('swapBBtn');

// -- Abis --
const ABI = [
            "function addLiquidity(uint256 amountA, uint256 amountB) external",
            "function removeLiquidity(uint256 shareAmount) external",
            "function swapAforB(uint256 amountAIn) external returns (uint256)",
            "function swapBforA(uint256 amountBIn) external returns (uint256)",
            "function initialFunding(address newUser) external",
            "function reserveA() view returns (uint256)",
            "function reserveB() view returns (uint256)",
            "function shares(address) view returns (uint256)",
            "function tokenA() view returns (address)",
            "function tokenB() view returns (address)"
        ];

const TOKEN_ABI = [
    "function approve(address spender, uint256 amount) external returns (bool)",
    "function balanceOf(address account) external view returns (uint256)",
    "function name() external view returns (string)",
    "function symbol() external view returns (string)"
];

let provider, signer, contract, account;

// -- Connect Wallet --
async function connectWallet() {
    if (typeof window.ethereum === 'undefined') {
        alert('Please install MetaMask!');
        return;
    }

    try {
        await window.ethereum.request({ method: 'eth_requestAccounts' });
        provider = new ethers.BrowserProvider(window.ethereum);
        signer = await provider.getSigner();
        account = await signer.getAddress();
        contract = new ethers.Contract(CONTRACT_ADDRESS, ABI, signer);

        document.getElementById('statusText').textContent = 'Connected';
        document.getElementById('account').textContent = account;
        document.getElementById('connectBtn').textContent = 'Connected';
        document.getElementById('connectBtn').disabled = true;

        await updateReserves();
        await updateShares();
        await updateBalances();
    } catch (error) {
        console.error('Connection error:', error);
        alert('Failed to connect wallet');
    }
}

// -- Update UI funxs --
// -- Updates, reserves of a and b--
async function updateReserves() {
    const resA = await contract.reserveA();
    const resB = await contract.reserveB();
    document.getElementById('reserveA').textContent = ethers.formatEther(resA);
    document.getElementById('reserveB').textContent = ethers.formatEther(resB);
}

// -- Updates share held by user--
async function updateShares() {
    const userShares = await contract.shares(account);
    document.getElementById('yourShares').textContent = ethers.formatEther(userShares);
}

// -- updates the token balances of user--
async function updateBalances() {
    const tokenA = new ethers.Contract(TOKEN_A_ADDRESS, TOKEN_ABI, signer);
    const tokenB = new ethers.Contract(TOKEN_B_ADDRESS, TOKEN_ABI, signer);
    
    const balA = await tokenA.balanceOf(account);
    const balB = await tokenB.balanceOf(account);
    
    document.getElementById('balanceA').textContent = ethers.formatEther(balA);
    document.getElementById('balanceB').textContent = ethers.formatEther(balB);
}

// --approves tokenn transfer--
async function approveToken(tokenAddress, amount) {
    const token = new ethers.Contract(tokenAddress, TOKEN_ABI, signer);
    const tx = await token.approve(CONTRACT_ADDRESS, amount);
    await tx.wait();
}

connectBtn.addEventListener('click', connectWallet);

// -- onclick button events listeners--
// -- Initial funding event listener--
initialFundBtn.addEventListener('click', async () => {
    try {
        document.getElementById('fundError').textContent = '';
        document.getElementById('fundSuccess').textContent = '';
        const tx = await contract.initialFunding(account);
        await tx.wait();
        await updateBalances();
        document.getElementById('fundSuccess').textContent = 'Funding successful!';
    } catch (error) {
        document.getElementById('fundError').textContent = error.message;
    }
});

let tokensApproved = false;

// -- Add liquidity event listener--
addLiquidityBtn.addEventListener('click', async () => {
    try {
        document.getElementById('addError').textContent = '';
        document.getElementById('addSuccess').textContent = '';
        
        const amountA = ethers.parseEther(document.getElementById('addAmountA').value);
        const amountB = ethers.parseEther(document.getElementById('addAmountB').value);
        
        // First click: Approve both tokens
        if (!tokensApproved) {
            const tokenA = new ethers.Contract(TOKEN_A_ADDRESS, TOKEN_ABI, signer);
            const tokenB = new ethers.Contract(TOKEN_B_ADDRESS, TOKEN_ABI, signer);
            
            const txA = await tokenA.approve(CONTRACT_ADDRESS, amountA);
            const txB = await tokenB.approve(CONTRACT_ADDRESS, amountB);
            
            // Wait for both approvals to complete
            await Promise.all([txA.wait(), txB.wait()]);
            
            tokensApproved = true;
            document.getElementById('addLiqBtn').textContent = 'Confirm Add Liquidity';
            document.getElementById('addSuccess').textContent = 'Tokens approved! Click again to add liquidity.';
            return;
        }
        
        // Second click: Add liquidity
        const tx = await contract.addLiquidity(amountA, amountB);
        await tx.wait();
        
        await updateReserves();
        await updateShares();
        await updateBalances();
        
        // Reset state
        tokensApproved = false;
        document.getElementById('addLiqBtn').textContent = 'Add Liquidity';
        document.getElementById('addSuccess').textContent = 'Liquidity added successfully!';
    } catch (error) {
        tokensApproved = false;
        document.getElementById('addLiqBtn').textContent = 'Add Liquidity';
        document.getElementById('addError').textContent = error.message;
    }
});

// -- Remove liquidity event listener--
removeLiquidityBtn.addEventListener('click', async () => {
    try {
        document.getElementById('removeError').textContent = '';
        document.getElementById('removeSuccess').textContent = '';
        
        const shares = ethers.parseEther(document.getElementById('removeShares').value);
        const tx = await contract.removeLiquidity(shares);
        await tx.wait();
        
        await updateReserves();
        await updateShares();
        await updateBalances();
        
        document.getElementById('removeSuccess').textContent = 'Liquidity removed successfully!';
    } catch (error) {
        document.getElementById('removeError').textContent = error.message;
    }
});

// -- Swap A for B event listener--
swapAButton.addEventListener('click', async () => {
    try {
        document.getElementById('swapError').textContent = '';
        document.getElementById('swapSuccess').textContent = '';
        
        const amount = ethers.parseEther(document.getElementById('swapAAmount').value);
        await approveToken(TOKEN_A_ADDRESS, amount);

        const tx = await contract.swapAforB(amount);
        await tx.wait();
        
        await updateReserves();
        await updateBalances();
        
        document.getElementById('swapSuccess').textContent = 'Swap successful!';
    } catch (error) {
        document.getElementById('swapError').textContent = error.message;
    }
});

// -- Swap B for A event listener--
swapBButton.addEventListener('click', async () => {
    try {
        document.getElementById('swapError').textContent = '';
        document.getElementById('swapSuccess').textContent = '';
        
        const amount = ethers.parseEther(document.getElementById('swapBAmount').value);
        await approveToken(TOKEN_B_ADDRESS, amount);

        const tx = await contract.swapBforA(amount);
        await tx.wait();
        
        await updateReserves();
        await updateBalances();
        
        document.getElementById('swapSuccess').textContent = 'Swap successful!';
    } catch (error) {
        document.getElementById('swapError').textContent = error.message;
    }
});