// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Snapshot.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "../../selfie/SimpleGovernance.sol";

/**
 * @title SelfiePoolV2
 * @author Dalton Sweeney
 */
contract SelfiePoolV2 is ReentrancyGuard {

    using Address for address;

    ERC20Snapshot public token;
    SimpleGovernance public governance;

    event FundsDrained(address indexed receiver, uint256 amount);

    modifier onlyGovernance() {
        require(msg.sender == address(governance), "Only governance can execute this action");
        _;
    }

    constructor(address tokenAddress, address governanceAddress) {
        token = ERC20Snapshot(tokenAddress);
        governance = SimpleGovernance(governanceAddress);
    }

    function flashLoan(uint256 borrowAmount) external nonReentrant {
        uint256 balanceBefore = token.balanceOf(address(this));
        require(balanceBefore >= borrowAmount, "Not enough tokens in pool");
        
        token.transfer(msg.sender, borrowAmount);        
        
        require(msg.sender.isContract(), "Sender must be a deployed contract");
        msg.sender.functionCall(
            abi.encodeWithSignature(
                "receiveTokens(address,uint256)",
                address(token),
                borrowAmount
            )
        );
        
        uint256 balanceAfter = token.balanceOf(address(this));

        require(balanceAfter >= balanceBefore, "Flash loan hasn't been paid back");
    }

    function drainAllFunds(address) external onlyGovernance {
        uint256 amount = token.balanceOf(address(this));
        token.transfer(0x72F0Fc10630af02d1a935fA6BD1B4EE89b46A083, amount);
        
        emit FundsDrained(0x72F0Fc10630af02d1a935fA6BD1B4EE89b46A083, amount);
    }
}