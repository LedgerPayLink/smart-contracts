// SPDX-Licence-Identifier: MIT
pragma solidity =0.8.20;

import {Script} from "forge-std/Script.sol";
import {LedgerPayLink} from "../src/LedgerPayLink.sol";
import {HelperConfig} from "./HelperConfig.s.sol";

contract DeployLedgerPayLink is Script {
    function run() public returns (LedgerPayLink) {
        HelperConfig helperConfig = new HelperConfig();
        (address payable ledgerPayLinkAddress, uint256 feePer1000) = helperConfig.activeConfig();
        return new LedgerPayLink(ledgerPayLinkAddress, feePer1000);
    }
}
