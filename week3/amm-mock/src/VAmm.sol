// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

// import "lib/@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {MockERC20} from "./MockERC20.sol";

contract VAmm {
    using Math for uint256;
    using SafeERC20 for MockERC20;
    
    // --STATE VARIABLES--
    MockERC20 public tokenA;
    MockERC20 public tokenB;

    uint256 public reserveA;
    uint256 public reserveB;
    uint256 public totalShares;

    mapping(address => uint256) public shares;
    mapping(address => bool) public isFunded;

    // --EVENTS--
    event LiquidityAdded(address indexed lp, uint256 amountA, uint256 amountB);
    event LiquidityRemoved(address indexed lp, uint256 amountA, uint256 amountB);
    event Swap(address indexed swapper, address indexed fromToken, uint256 amountIn, address indexed toToken, uint256 amountOut);


    // --CONSTRUCTOR--
    constructor(address _tokenA, address _tokenB) {
        tokenA = MockERC20(_tokenA);
        tokenB = MockERC20(_tokenB);
    }

    // --FUNCTIONS--
    // this differs from uniswap v2 where lp can give any ratio of tokens
    function addLiquidity(uint256 amountA, uint256 amountB) external {
        require(amountA > 0 && amountB > 0, "Amounts must be greater than zero");

        uint256 sharesToMint;
        uint256 usedA = amountA;
        uint256 usedB = amountB;
        
        if (totalShares == 0) {
            sharesToMint = Math.sqrt(amountA * amountB);
        } else {
            // Calculate maximum amounts that can be used based on current ratio
            uint256 maxAForB = (amountB * reserveA) / reserveB;
            uint256 maxBForA = (amountA * reserveB) / reserveA;
            
            // Cap the amounts to prevent exceeding the pool ratio
            if (amountA > maxAForB) {
                usedA = maxAForB;
            }
            if (amountB > maxBForA) {
                usedB = maxBForA;
            }
            
            // take min of the two ratios scaled to totalsharevalue
            sharesToMint = Math.min(
                (usedA * totalShares) / reserveA,
                (usedB * totalShares) / reserveB
            );
        }

        require(sharesToMint > 0, "Insufficient liquidity provided");

        // Only transfer what we'll use
        tokenA.transferFrom(msg.sender, address(this), usedA);
        tokenB.transferFrom(msg.sender, address(this), usedB);
        

        reserveA += usedA;
        reserveB += usedB;
        totalShares += sharesToMint;
        shares[msg.sender] += sharesToMint;

        emit LiquidityAdded(msg.sender, usedA, usedB);
    }

    function removeLiquidity(uint256 shareAmount) external {
        require(shareAmount > 0 && shareAmount <= shares[msg.sender], "Invalid share amount");

        uint256 amountA = (shareAmount * reserveA) / totalShares;
        uint256 amountB = (shareAmount * reserveB) / totalShares;

        shares[msg.sender] -= shareAmount;
        totalShares -= shareAmount;
        reserveA -= amountA;
        reserveB -= amountB;

        tokenA.transfer(msg.sender, amountA);
        tokenB.transfer(msg.sender, amountB);

        emit LiquidityRemoved(msg.sender, amountA, amountB);
    }

    function swapAforB(uint256 amountAIn) external returns (uint256 amountBOut) {
        require(amountAIn > 0, "Amount must be greater than zero");
        require(reserveA > 0 && reserveB > 0, "Insufficient liquidity");

        amountBOut = getAmountOut(amountAIn, reserveA, reserveB);
        require(amountBOut > 0, "Insufficient output amount");
        require(tokenB.balanceOf(address(this)) >= amountBOut, "Insufficient pool balance");

        tokenA.transferFrom(msg.sender, address(this), amountAIn);
        tokenB.transfer(msg.sender, amountBOut);

        reserveA += amountAIn;
        reserveB -= amountBOut;

        emit Swap(msg.sender, address(tokenA), amountAIn, address(tokenB), amountBOut);
        return amountBOut;
    }

    function swapBforA(uint256 amountBIn) external returns (uint256 amountAOut) {
        require(amountBIn > 0, "Amount must be greater than zero");
        require(reserveA > 0 && reserveB > 0, "Insufficient liquidity");

        amountAOut = getAmountOut(amountBIn, reserveB, reserveA);
        require(amountAOut > 0, "Insufficient output amount");
        require(tokenA.balanceOf(address(this)) >= amountAOut, "Insufficient pool balance");

        tokenB.transferFrom(msg.sender, address(this), amountBIn);
        tokenA.transfer(msg.sender, amountAOut);

        reserveB += amountBIn;
        reserveA -= amountAOut;

        emit Swap(msg.sender, address(tokenB), amountBIn, address(tokenA), amountAOut);
        return amountAOut;
    }
    
    function initialFunding(address newUser) external {
        require(!isFunded[newUser], "User already funded");
        tokenA.mint(newUser, 1000 * 10**18);
        tokenB.mint(newUser, 1000 * 10**18);
        isFunded[newUser] = true;
    }

    // --HELPER FUNCTIONS--
    function getAmountOut(uint256 amountIn, uint256 reserveIn, uint256 reserveOut) internal pure returns (uint256 amountOut) {
        require (amountIn > 0, "Insufficient input amount");
        require (reserveIn > 0 && reserveOut > 0, "Insufficient liquidity");

        uint256 amountInWithPlatformFee = amountIn * 997/1000; // std uniswap fee of 0.3% from book
        uint256 numerator = amountInWithPlatformFee * reserveOut;
        uint256 denominator = reserveIn + amountInWithPlatformFee;
        amountOut = numerator / denominator;
        return amountOut;
    }
}
// Main functions:
// 1. addLiquidity
// 2. removeLiquidity
// 3. swap
// helper function: calculate output based on input and existing reserves