// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.8.20;

import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";

abstract contract Pay {
    using SafeERC20 for IERC20;

    address payable public immutable i_ledgerPayLinkAddress;
    uint256 public immutable i_feePer1000; //20 = 2%

    constructor(address payable ledgerPayLinkAddress, uint256 feePer1000) {
        require(address(0) != ledgerPayLinkAddress);
        i_ledgerPayLinkAddress = ledgerPayLinkAddress;
        i_feePer1000 = feePer1000;
    }

    function _payWithETH(
        uint256 amount,
        address payable destinationAddress
    ) internal {
        uint256 ethSent = msg.value;
        require(amount <= ethSent, "LedgerPayLink Error: not enough ETH sent");
        (uint256 feeAmount, uint256 destinationAmount) = _getAmounts(ethSent);

        (bool LPLSent, ) = i_ledgerPayLinkAddress.call{value: feeAmount}("");
        require(LPLSent, "Failed to send Ether to fee wallet");
        (bool destinationSent, ) = destinationAddress.call{
            value: destinationAmount
        }("");
        require(destinationSent, "Failed to send Ether to destination account");
    }

    function _payWithToken(
        address tokenAddress,
        uint256 tokenAmount,
        address destinationAddress
    ) internal {
        IERC20(tokenAddress).safeTransferFrom(
            msg.sender,
            address(this),
            tokenAmount
        );
        (uint256 feeAmount, uint256 destinationAmount) = _getAmounts(
            tokenAmount
        );

        IERC20(tokenAddress).safeTransfer(i_ledgerPayLinkAddress, feeAmount);
        IERC20(tokenAddress).safeTransfer(
            destinationAddress,
            destinationAmount
        );
    }

    function _getAmounts(
        uint256 amountSubmitted
    ) private view returns (uint256 feeAmount, uint256 destinationAmount) {
        feeAmount = (amountSubmitted / 1000) * i_feePer1000;
        destinationAmount = amountSubmitted - feeAmount;
    }
}
