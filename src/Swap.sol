// SPDX-License-Identifier: MIT

// Pragma statements
// Import statements
// Events
// Errors
// Interfaces
// Libraries
// Contracts

pragma solidity =0.8.20;

import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";
import {ISwapRouter} from "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";

abstract contract Swap {
    // Type declarations
    // State variables
    // Events
    // Errors
    // Modifiers
    // Functions

    using SafeERC20 for IERC20;

    address public immutable i_weth;
    ISwapRouter public immutable i_swapRouter;

    // constructor
    // receive function (if exists)
    // fallback function (if exists)
    // external
    // public
    // internal
    // private

    constructor(address weth, address swapRouter) {
        i_weth = weth;
        i_swapRouter = ISwapRouter(swapRouter);
    }

    receive() external payable {}

    function _swapExactInputSingle(
        address tokenIn,
        address tokenOut,
        uint24 poolFeeX10000,
        uint256 amountIn,
        uint256 amountOutMinimum
    ) internal returns (uint256 amountOut) {
        // msg.sender must approve this contract

        // Transfer the specified amount of tokenIn to this contract.
        IERC20(tokenIn).safeTransferFrom(msg.sender, address(this), amountIn);

        // Approve the router to spend tokenIn.
        IERC20(tokenIn).safeIncreaseAllowance(address(i_swapRouter), amountIn);

        // Naively set amountOutMinimum to 0. In production, use an oracle or other data source to choose a safer value for amountOutMinimum.
        // We also set the sqrtPriceLimitx96 to be 0 to ensure we swap our exact input amount.
        ISwapRouter.ExactInputSingleParams memory params = ISwapRouter
            .ExactInputSingleParams({
                tokenIn: tokenIn,
                tokenOut: tokenOut,
                fee: poolFeeX10000,
                recipient: tokenOut == i_weth ? address(this) : msg.sender, // If tokenOut is WETH the SC is the recipient and then it'll withdraw ETH from WETH contract and then send it to the user
                deadline: block.timestamp,
                amountIn: amountIn,
                amountOutMinimum: amountOutMinimum,
                sqrtPriceLimitX96: 0
            });

        // The call to `exactInputSingle` executes the swap.
        amountOut = i_swapRouter.exactInputSingle(params);
    }

    function _swapExactInputSingleWithETH(
        address tokenOut,
        uint24 poolFeeX10000,
        uint256 amountOutMinimum
    ) internal returns (uint256 amountOut) {
        address tokenIn = i_weth;
        uint256 amountIn = msg.value;

        ISwapRouter.ExactInputSingleParams memory params = ISwapRouter
            .ExactInputSingleParams({
                tokenIn: tokenIn,
                tokenOut: tokenOut,
                fee: poolFeeX10000,
                recipient: msg.sender,
                deadline: block.timestamp,
                amountIn: amountIn,
                amountOutMinimum: amountOutMinimum,
                sqrtPriceLimitX96: 0
            });

        // The call to `exactInputSingle` executes the swap.
        amountOut = i_swapRouter.exactInputSingle{value: amountIn}(params);
    }

    function _swapExactOutputSingle(
        address tokenIn,
        address tokenOut,
        uint24 poolFeeX10000,
        uint256 amountInMaximum,
        uint256 amountOut,
        address swapper
    ) internal returns (uint256 amountIn) {
        // Transfer the specified amount of DAI to this contract.
        IERC20(tokenIn).safeTransferFrom(
            msg.sender,
            address(this),
            amountInMaximum
        );

        // Approve the router to spend the specifed `amountInMaximum` of DAI.
        // In production, you should choose the maximum amount to spend based on oracles or other data sources to acheive a better swap.
        IERC20(tokenIn).safeIncreaseAllowance(
            address(i_swapRouter),
            amountInMaximum
        );

        ISwapRouter.ExactOutputSingleParams memory params = ISwapRouter
            .ExactOutputSingleParams({
                tokenIn: tokenIn,
                tokenOut: tokenOut,
                fee: poolFeeX10000,
                recipient: msg.sender,
                deadline: block.timestamp,
                amountOut: amountOut,
                amountInMaximum: amountInMaximum,
                sqrtPriceLimitX96: 0
            });

        // Executes the swap returning the amountIn needed to spend to receive the desired amountOut.
        amountIn = i_swapRouter.exactOutputSingle(params);

        // For exact output swaps, the amountInMaximum may not have all been spent.
        // If the actual amount spent (amountIn) is less than the specified maximum amount, we must refund the msg.sender and approve the swapRouter to spend 0.
        if (amountIn < amountInMaximum) {
            IERC20(tokenIn).forceApprove(address(i_swapRouter), 0);
            IERC20(tokenIn).safeTransfer(swapper, amountInMaximum - amountIn);
        }
    }
}
