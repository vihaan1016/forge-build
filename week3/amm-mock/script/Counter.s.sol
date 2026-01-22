// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import {Script} from "forge-std/Script.sol";
import {VAmm} from "../src/VAmm.sol";
import {TokenA, TokenB} from "../src/MockERC20.sol";
import {console} from "forge-std/console.sol";

contract VammScript is Script {
    VAmm public vamm;
    TokenA public tokenA;
    TokenB public tokenB;

    function setUp() public {}

    function run() public {
        vm.startBroadcast();

        tokenA = new TokenA();
        tokenB = new TokenB();
        vamm = new VAmm(address(tokenA), address(tokenB));

        vm.stopBroadcast();

        // Log the addresses
        console.log("TokenA deployed at:", address(tokenA));
        console.log("TokenB deployed at:", address(tokenB));
        console.log("VAmm deployed at:", address(vamm));
    }
}