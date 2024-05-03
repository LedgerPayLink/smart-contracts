// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.8.20;

import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";

abstract contract Pay {
    error Pay__NotEnoughETHSent();
    error Pay__ETHNotSentToFeeAddress();
    error Pay__ETHNotSentToDestinationAddress();
    error Pay__DestinationNullAddress();
    error Pay__ZeroTokenAmount();

    using SafeERC20 for IERC20;

    address payable private immutable i_feeAddress;
    uint256 private immutable i_feePer1000; //20 = 2%

    constructor(address payable ledgerPayLinkAddress, uint256 feePer1000) {
        require(address(0) != ledgerPayLinkAddress);
        i_feeAddress = ledgerPayLinkAddress;
        i_feePer1000 = feePer1000;
    }

    receive() external payable {}

    function _payWithETH(uint256 amount, address payable destinationAddress) internal {
        if (address(0) == destinationAddress) {
            revert Pay__DestinationNullAddress();
        }
        uint256 ethSent = msg.value;
        if (amount > ethSent) {
            revert Pay__NotEnoughETHSent();
        }
        (uint256 feeAmount, uint256 destinationAmount) = _getAmounts(ethSent);

        (bool feeSentSuccessfully,) = i_feeAddress.call{value: feeAmount}("");
        if (!feeSentSuccessfully) {
            revert Pay__ETHNotSentToFeeAddress();
        }
        (bool amountSentSuccessfully,) = destinationAddress.call{value: destinationAmount}("");
        if (!amountSentSuccessfully) {
            revert Pay__ETHNotSentToDestinationAddress();
        }
    }

    function _payWithToken(address tokenAddress, uint256 tokenAmount, address destinationAddress) internal {
        if (address(0) == destinationAddress) {
            revert Pay__DestinationNullAddress();
        }

        if (tokenAmount == 0) {
            revert Pay__ZeroTokenAmount();
        }

        IERC20(tokenAddress).safeTransferFrom(msg.sender, address(this), tokenAmount);
        (uint256 feeAmount, uint256 destinationAmount) = _getAmounts(tokenAmount);

        IERC20(tokenAddress).safeTransfer(i_feeAddress, feeAmount);
        IERC20(tokenAddress).safeTransfer(destinationAddress, destinationAmount);
    }

    function _getAmounts(uint256 amountSubmitted) private view returns (uint256 feeAmount, uint256 destinationAmount) {
        feeAmount = (amountSubmitted / 1000) * i_feePer1000;
        destinationAmount = amountSubmitted - feeAmount;
    }

    function getFeeAddress() external view returns (address payable) {
        return i_feeAddress;
    }

    function getFeePer1000() external view returns (uint256) {
        return i_feePer1000;
    }
}
