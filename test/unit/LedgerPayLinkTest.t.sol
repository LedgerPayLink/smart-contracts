// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.8.20;

import {Test} from "forge-std/Test.sol";
import {console} from "forge-std/console.sol";
import {DeployLedgerPayLink} from "../../script/DeployLedgerPayLink.s.sol";
import {LedgerPayLink} from "../../src/LedgerPayLink.sol";
import {Pay} from "../../src/Pay.sol";
import {ERC20Mock} from "../mocks/ERC20Mock.sol";

contract LedgerPayLinkTest is Test {
    LedgerPayLink ledgerPayLink;
    address payable feeAddress;
    uint256 feePer1000;
    address destinationAddress = makeAddr("destinationAddress");
    ERC20Mock token;

    event LPL_PaidWithETH(string indexed paymentId, uint256 ethAmount, address destination);
    event LPL_PaidWithToken(string indexed paymentId, address tokenAddress, uint256 tokenAmount, address destination);

    function setUp() public {
        DeployLedgerPayLink deployer = new DeployLedgerPayLink();
        ledgerPayLink = deployer.run();
        feeAddress = ledgerPayLink.getFeeAddress();
        feePer1000 = ledgerPayLink.getFeePer1000();
        token = new ERC20Mock();
    }

    // PayWithETH
    function testRevertIfDetinationAddressIsNull() public {
        uint256 amount = 0.1 ether;
        address payable destination = payable(address(0));
        vm.expectRevert(Pay.Pay__DestinationNullAddress.selector);
        ledgerPayLink.payWithETH{value: amount}(amount, destination, "paymentId");
    }

    function testRevertIfNotEnoughEthSent() public {
        uint256 amount = 0.1 ether;
        uint256 ethSent = 0.01 ether;
        address payable destination = payable(address(this));
        vm.expectRevert(Pay.Pay__NotEnoughETHSent.selector);
        ledgerPayLink.payWithETH{value: ethSent}(amount, destination, "paymentId");
    }

    function testETHFeeAndAmountSentSuccessfully() public {
        uint256 amount = 0.1 ether;
        uint256 feeAmount = (amount / 1000) * feePer1000;
        uint256 destinationAmount = amount - feeAmount;
        ledgerPayLink.payWithETH{value: amount}(amount, payable(destinationAddress), "paymentId");
        assertEq(destinationAddress.balance, destinationAmount);
        assertEq(feeAddress.balance, feeAmount);
        console.log("feeAddress.balance", feeAddress.balance);
        console.log("destinationAddress.balance", destinationAddress.balance);
    }

    function testEventIsEmittedAfterPaymentWithETH() public {
        uint256 amount = 0.1 ether;
        vm.expectEmit(true, false, false, true, address(ledgerPayLink));
        emit LPL_PaidWithETH("paymentId", amount, destinationAddress);
        ledgerPayLink.payWithETH{value: amount}(amount, payable(destinationAddress), "paymentId");
    }

    //PayWithToken
    function testRevertIfDetinationAddressIsNullToken() public {
        address tokenAddress = makeAddr("tokenAddress");
        uint256 tokenAmount = 1 ether;
        address destination = address(0);
        vm.expectRevert(Pay.Pay__DestinationNullAddress.selector);
        ledgerPayLink.payWithToken(tokenAddress, tokenAmount, destination, "paymentId");
    }

    function testRevertIfTokenAmountIsZero() public {
        address tokenAddress = makeAddr("tokenAddress");
        uint256 tokenAmount = 0;
        vm.expectRevert(Pay.Pay__ZeroTokenAmount.selector);
        ledgerPayLink.payWithToken(tokenAddress, tokenAmount, destinationAddress, "paymentId");
    }

    function testTokenAmountFeeAndAmountSentSuccessfully() public {
        address tokenAddress = address(token);
        uint256 tokenAmount = 1 ether;
        uint256 feeAmount = (tokenAmount / 1000) * feePer1000;
        uint256 destinationAmount = tokenAmount - feeAmount;
        token.mint(address(this), tokenAmount);
        token.approve(address(ledgerPayLink), tokenAmount);
        ledgerPayLink.payWithToken(tokenAddress, tokenAmount, destinationAddress, "paymentId");
        assertEq(token.balanceOf(destinationAddress), destinationAmount);
        assertEq(token.balanceOf(feeAddress), feeAmount);
        console.log("feeAddress.balance", token.balanceOf(feeAddress));
        console.log("destinationAddress.balance", token.balanceOf(destinationAddress));
    }

    function testEventIsEmittedAfterPaymentWithToken() public {
        address tokenAddress = address(token);
        uint256 tokenAmount = 1 ether;
        token.mint(address(this), tokenAmount);
        token.approve(address(ledgerPayLink), tokenAmount);
        vm.expectEmit(true, false, false, true, address(ledgerPayLink));
        emit LPL_PaidWithToken("paymentId", tokenAddress, tokenAmount, destinationAddress);
        ledgerPayLink.payWithToken(tokenAddress, tokenAmount, destinationAddress, "paymentId");
    }
}
