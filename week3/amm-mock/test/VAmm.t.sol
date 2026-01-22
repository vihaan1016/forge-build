// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Test} from "forge-std/Test.sol";
import {VAmm} from "../src/VAmm.sol";
import {MockERC20, TokenA, TokenB} from "../src/MockERC20.sol";

contract VAmmTest is Test {
    VAmm public amm;
    TokenA public tokenA;
    TokenB public tokenB;

    address public lp1 = address(0x1);
    address public lp2 = address(0x2);
    address public trader = address(0x3);

    function setUp() public {
        // Deploy tokens
        tokenA = new TokenA();
        tokenB = new TokenB();

        // Deploy AMM
        amm = new VAmm(address(tokenA), address(tokenB));

        // Mint tokens to AMM for initial funding (significantly increased)
        tokenA.mint(address(amm), 10000000 * 10**18);
        tokenB.mint(address(amm), 10000000 * 10**18);

        // Fund test addresses with initial amounts
        vm.prank(address(amm));
        amm.initialFunding(lp1);

        vm.prank(address(amm));
        amm.initialFunding(lp2);

        vm.prank(address(amm));
        amm.initialFunding(trader);

        // Directly mint tokens to traders for swapping (in addition to initialFunding)
        tokenA.mint(lp1, 100000 * 10**18);
        tokenB.mint(lp1, 100000 * 10**18);
        tokenA.mint(trader, 100000 * 10**18);
        tokenB.mint(trader, 100000 * 10**18);
    }

    // ========== LIQUIDITY PROVIDER TESTS ==========

    function test_AddLiquidity_FirstProvider() public {
        vm.startPrank(lp1);
        tokenA.approve(address(amm), 100 * 10**18);
        tokenB.approve(address(amm), 100 * 10**18);

        amm.addLiquidity(100 * 10**18, 100 * 10**18);

        assertEq(amm.reserveA(), 100 * 10**18);
        assertEq(amm.reserveB(), 100 * 10**18);
        assertEq(amm.totalShares(), 100 * 10**18); // sqrt(100 * 100) = 100
        assertEq(amm.shares(lp1), 100 * 10**18);
        vm.stopPrank();
    }

    function test_AddLiquidity_SecondProvider() public {
        // First provider
        vm.startPrank(lp1);
        tokenA.approve(address(amm), 100 * 10**18);
        tokenB.approve(address(amm), 100 * 10**18);
        amm.addLiquidity(100 * 10**18, 100 * 10**18);
        vm.stopPrank();

        // Second provider with same ratio
        vm.startPrank(lp2);
        tokenA.approve(address(amm), 100 * 10**18);
        tokenB.approve(address(amm), 100 * 10**18);
        amm.addLiquidity(100 * 10**18, 100 * 10**18);
        vm.stopPrank();

        assertEq(amm.reserveA(), 200 * 10**18);
        assertEq(amm.reserveB(), 200 * 10**18);
        assertEq(amm.totalShares(), 200 * 10**18);
        assertEq(amm.shares(lp2), 100 * 10**18);
    }

    function test_AddLiquidity_ImbalancedInput() public {
        vm.startPrank(lp1);
        tokenA.approve(address(amm), 100 * 10**18);
        tokenB.approve(address(amm), 100 * 10**18);
        amm.addLiquidity(100 * 10**18, 100 * 10**18);
        vm.stopPrank();

        // Second provider with imbalanced ratio (more A than B)
        vm.startPrank(lp2);
        tokenA.approve(address(amm), 200 * 10**18);
        tokenB.approve(address(amm), 100 * 10**18);
        amm.addLiquidity(200 * 10**18, 100 * 10**18);
        vm.stopPrank();

        // Should mint shares based on minimum ratio
        // maxAForB = (100 * 100) / 100 = 100
        // usedA = min(200, 100) = 100
        // usedB = min(100, 200) = 100
        // Shares: min((100 * 100) / 100, (100 * 100) / 100) = 100
        assertEq(amm.shares(lp2), 100 * 10**18);
        assertEq(tokenA.balanceOf(lp2), 900 * 10**18 + 100 * 10**18); // Got refund of excess 100A
        assertEq(tokenB.balanceOf(lp2), 900 * 10**18); // Used 100B
    }

    function test_AddLiquidity_ZeroAmount() public {
        vm.startPrank(lp1);
        tokenA.approve(address(amm), 100 * 10**18);
        tokenB.approve(address(amm), 0);

        vm.expectRevert("Amounts must be greater than zero");
        amm.addLiquidity(100 * 10**18, 0);
        vm.stopPrank();
    }

    function test_RemoveLiquidity_FullWithdraw() public {
        vm.startPrank(lp1);
        tokenA.approve(address(amm), 100 * 10**18);
        tokenB.approve(address(amm), 100 * 10**18);
        amm.addLiquidity(100 * 10**18, 100 * 10**18);

        uint256 sharesToRemove = amm.shares(lp1);
        amm.removeLiquidity(sharesToRemove);

        assertEq(amm.reserveA(), 0);
        assertEq(amm.reserveB(), 0);
        assertEq(amm.totalShares(), 0);
        assertEq(amm.shares(lp1), 0);
        vm.stopPrank();
    }

    function test_RemoveLiquidity_PartialWithdraw() public {
        vm.startPrank(lp1);
        tokenA.approve(address(amm), 100 * 10**18);
        tokenB.approve(address(amm), 100 * 10**18);
        amm.addLiquidity(100 * 10**18, 100 * 10**18);

        uint256 sharesToRemove = 50 * 10**18;
        amm.removeLiquidity(sharesToRemove);

        assertEq(amm.reserveA(), 50 * 10**18);
        assertEq(amm.reserveB(), 50 * 10**18);
        assertEq(amm.totalShares(), 50 * 10**18);
        assertEq(amm.shares(lp1), 50 * 10**18);
        vm.stopPrank();
    }

    function test_RemoveLiquidity_InvalidAmount() public {
        vm.startPrank(lp1);
        tokenA.approve(address(amm), 100 * 10**18);
        tokenB.approve(address(amm), 100 * 10**18);
        amm.addLiquidity(100 * 10**18, 100 * 10**18);

        vm.expectRevert("Invalid share amount");
        amm.removeLiquidity(200 * 10**18); // More than LP has
        vm.stopPrank();
    }

    // ========== SWAP TESTS ==========

    function test_SwapAforB() public {
        // Setup liquidity
        vm.startPrank(lp1);
        tokenA.approve(address(amm), 100 * 10**18);
        tokenB.approve(address(amm), 100 * 10**18);
        amm.addLiquidity(100 * 10**18, 100 * 10**18);
        vm.stopPrank();

        // Execute swap
        vm.startPrank(trader);
        tokenA.approve(address(amm), 10 * 10**18);
        uint256 amountOut = amm.swapAforB(10 * 10**18);
        vm.stopPrank();

        // Verify swap math (with 0.3% fee)
        // amountInWithFee = 10 * 997/1000 = 9.97
        // amountOut = (9.97 * 100) / (100 + 9.97) = 997 / 109.97 ≈ 9.064
        assertGt(amountOut, 0);
        assertLt(amountOut, 10 * 10**18); // Should be less due to fee
        assertEq(amm.reserveA(), 110 * 10**18);
        assertLt(amm.reserveB(), 100 * 10**18);
    }

    function test_SwapBforA() public {
        // Setup liquidity
        vm.startPrank(lp1);
        tokenA.approve(address(amm), 100 * 10**18);
        tokenB.approve(address(amm), 100 * 10**18);
        amm.addLiquidity(100 * 10**18, 100 * 10**18);
        vm.stopPrank();

        // Execute swap
        vm.startPrank(trader);
        tokenB.approve(address(amm), 10 * 10**18);
        uint256 amountOut = amm.swapBforA(10 * 10**18);
        vm.stopPrank();

        assertGt(amountOut, 0);
        assertLt(amountOut, 10 * 10**18);
        assertEq(amm.reserveB(), 110 * 10**18);
        assertLt(amm.reserveA(), 100 * 10**18);
    }

    function test_SwapAforB_NoLiquidity() public {
        vm.startPrank(trader);
        tokenA.approve(address(amm), 10 * 10**18);

        vm.expectRevert("Insufficient liquidity");
        amm.swapAforB(10 * 10**18);
        vm.stopPrank();
    }

    function test_SwapAforB_ZeroAmount() public {
        vm.startPrank(lp1);
        tokenA.approve(address(amm), 100 * 10**18);
        tokenB.approve(address(amm), 100 * 10**18);
        amm.addLiquidity(100 * 10**18, 100 * 10**18);
        vm.stopPrank();

        vm.startPrank(trader);
        vm.expectRevert("Amount must be greater than zero");
        amm.swapAforB(0);
        vm.stopPrank();
    }

    function test_Swap_ConstantProductFormula() public {
        vm.startPrank(lp1);
        tokenA.approve(address(amm), 1000 * 10**18);
        tokenB.approve(address(amm), 1000 * 10**18);
        amm.addLiquidity(1000 * 10**18, 1000 * 10**18);
        vm.stopPrank();

        uint256 reserveABefore = amm.reserveA();
        uint256 reserveBBefore = amm.reserveB();
        uint256 kBefore = reserveABefore * reserveBBefore;

        vm.startPrank(trader);
        tokenA.approve(address(amm), 100 * 10**18);
        amm.swapAforB(100 * 10**18);
        vm.stopPrank();

        uint256 reserveAAfter = amm.reserveA();
        uint256 reserveBAfter = amm.reserveB();
        uint256 kAfter = reserveAAfter * reserveBAfter;

        // FLAW: The constant product formula should be maintained
        // k should increase or stay same due to fees, not decrease
        // But due to the fee structure, k should actually increase
        assertGe(kAfter, kBefore);
    }

    // ========== INITIAL FUNDING TESTS ==========

    function test_InitialFunding_NewUser() public {
        address newUser = address(0x4);

        vm.prank(address(amm));
        amm.initialFunding(newUser);

        assertEq(tokenA.balanceOf(newUser), 1000 * 10**18);
        assertEq(tokenB.balanceOf(newUser), 1000 * 10**18);
    }

    function test_InitialFunding_AlreadyFunded() public {
        vm.startPrank(address(amm));
        // lp1 is already funded in setUp, so this should revert
        vm.expectRevert("User already funded");
        amm.initialFunding(lp1);
        vm.stopPrank();
    }

    function test_InitialFunding_OnlyOnce() public {
        address newUser = address(0x5);
        vm.startPrank(address(amm));
        
        amm.initialFunding(newUser);
        uint256 balanceAfterFirst = tokenA.balanceOf(newUser);

        vm.expectRevert();
        amm.initialFunding(newUser);
        
        assertEq(tokenA.balanceOf(newUser), balanceAfterFirst);
        vm.stopPrank();
    }

    // ========== INTEGRATION TESTS ==========

    function test_MultipleSwaps_SameDirection() public {
        vm.startPrank(lp1);
        tokenA.approve(address(amm), 50000 * 10**18);
        tokenB.approve(address(amm), 50000 * 10**18);
        amm.addLiquidity(50000 * 10**18, 50000 * 10**18);
        vm.stopPrank();

        vm.startPrank(trader);
        uint256 initialB = tokenB.balanceOf(trader);

        tokenA.approve(address(amm), 1000 * 10**18);
        uint256 swap1 = amm.swapAforB(100 * 10**18);
        uint256 swap2 = amm.swapAforB(100 * 10**18);
        uint256 swap3 = amm.swapAforB(100 * 10**18);

        // Second swap should yield less due to higher reserves of A
        assertGt(swap1, swap2);
        assertGt(swap2, swap3);

        assertEq(tokenB.balanceOf(trader), initialB + swap1 + swap2 + swap3);
        vm.stopPrank();
    }

    function test_SlippageImpact() public {
        vm.startPrank(lp1);
        tokenA.approve(address(amm), 100 * 10**18);
        tokenB.approve(address(amm), 100 * 10**18);
        amm.addLiquidity(100 * 10**18, 100 * 10**18);
        vm.stopPrank();

        vm.startPrank(trader);
        tokenA.approve(address(amm), 50 * 10**18);
        
        // Large swap on small liquidity should show slippage
        uint256 amountOut = amm.swapAforB(50 * 10**18);
        
        // Without fee: would be (50 * 100) / 150 = 33.33
        // With 0.3% fee: (49.85 * 100) / 149.85 ≈ 33.26
        assertLt(amountOut, 34 * 10**18);
        vm.stopPrank();
    }

    // ========== EDGE CASE TESTS ==========

    function testFuzz_AddLiquidity_RandomAmounts(uint256 amountA, uint256 amountB) public {
        vm.assume(amountA > 0 && amountA < 1e36);
        vm.assume(amountB > 0 && amountB < 1e36);
        vm.assume(amountA <= tokenA.balanceOf(lp1));
        vm.assume(amountB <= tokenB.balanceOf(lp1));

        vm.startPrank(lp1);
        tokenA.approve(address(amm), amountA);
        tokenB.approve(address(amm), amountB);
        amm.addLiquidity(amountA, amountB);
        vm.stopPrank();

        assertEq(amm.reserveA(), amountA);
        assertEq(amm.reserveB(), amountB);
    }

    function testFuzz_Swap_RandomAmounts(uint256 amountIn) public {
        vm.startPrank(lp1);
        tokenA.approve(address(amm), 50000 * 10**18);
        tokenB.approve(address(amm), 50000 * 10**18);
        amm.addLiquidity(50000 * 10**18, 50000 * 10**18);
        vm.stopPrank();

        // Ensure amountIn produces at least 1 unit of output
        // Lower bound set to 100 wei to avoid dust/rounding issues
        amountIn = bound(amountIn, 100, 5000 * 10**18);

        vm.startPrank(trader);
        tokenA.approve(address(amm), amountIn);
        uint256 amountOut = amm.swapAforB(amountIn);
        vm.stopPrank();

        // Amount out should be less than amount in due to fee
        assertLt(amountOut, amountIn);
    }
}
