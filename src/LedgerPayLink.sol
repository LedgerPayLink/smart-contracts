// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.8.20;

import {Pay} from "./Pay.sol";

contract LedgerPayLink is Pay {
    event LPL_PaidWithETH(string indexed paymentId, uint256 ethAmount, address destination);

    event LPL_PaidWithToken(string indexed paymentId, address tokenAddress, uint256 tokenAmount, address destination);

    constructor(address payable _LPLAddress, uint256 ledgerPayLinkFeePer1000)
        Pay(_LPLAddress, ledgerPayLinkFeePer1000)
    {}

    function payWithETH(uint256 amount, address payable destination, string calldata paymentId) external payable {
        _payWithETH(amount, destination);
        emit LPL_PaidWithETH(paymentId, amount, destination);
    }

    function payWithToken(address tokenAddress, uint256 tokenAmount, address destination, string calldata paymentId)
        external
    {
        _payWithToken(tokenAddress, tokenAmount, destination);
        emit LPL_PaidWithToken(paymentId, tokenAddress, tokenAmount, destination);
    }
}
