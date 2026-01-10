// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test} from "forge-std/Test.sol";
import {Ledger} from "../src/Counter.sol";

contract CounterTest is Test {
    Ledger public ledger;
    address public a;
    address public b;

    function setUp() public {
        ledger = new Ledger();
        a = makeAddr("a");
        b = makeAddr("b");
        vm.deal(a, 100 ether);
        vm.deal(b, 100 ether);
    }

    function test_Transfer() public {
        vm.startPrank(a);
        ledger.deposit{value: 20 ether}();
        ledger.transfer(10 ether, b);
        assertEq(ledger.getBalance(b), 10 ether);
        vm.stopPrank();
    }

    function test_Transfer_InsufficientBalance() public {
        vm.startPrank(a);
        ledger.deposit{value: 5 ether}();
        vm.expectRevert();
        ledger.transfer(1000 ether, b);
        vm.stopPrank();
    }
}
