// SPDX-License-Identifier: MIT
pragma solidity =0.8.20;

import {Script} from "forge-std/Script.sol";

contract HelperConfig is Script {
    struct Config {
        address payable ledgerPayLinkAddress;
        uint256 feePer1000;
    }

    Config public activeConfig;

    constructor() {
        if (block.chainid == 11155111) {
            activeConfig = getSepoliaETHConfig();
        } else if (block.chainid == 1) {
            activeConfig = getMainnetETHConfig();
        } else {
            activeConfig = getAnvilConfig();
        }
    }

    function getSepoliaETHConfig() public pure returns (Config memory) {
        return Config(payable(0x2B480c63bDe7C764cadBaA8b181405D770728128), 20);
    }

    function getMainnetETHConfig() public pure returns (Config memory) {
        return Config(payable(0x2B480c63bDe7C764cadBaA8b181405D770728128), 20);
    }

    function getAnvilConfig() public pure returns (Config memory) {
        return Config(payable(0x70997970C51812dc3A010C7d01b50e0d17dc79C8), 20);
    }
}
