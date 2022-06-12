// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "../../DamnValuableNFT.sol";

/**
 * @title FreeRiderNFTMarketplaceV2
 * @author Dalton Sweeney
 */
contract FreeRiderNFTMarketplaceV2 is ReentrancyGuard {

    using Address for address payable;

    DamnValuableNFT public token;
    uint256 public amountOfOffers;

    // tokenId -> price
    mapping(uint256 => uint256) private offers;

    event NFTOffered(address indexed offerer, uint256 tokenId, uint256 price);
    event NFTBought(address indexed buyer, uint256 tokenId, uint256 price);
    
    constructor(uint8 amountToMint) payable {
        require(amountToMint < 256, "Cannot mint that many tokens");
        token = new DamnValuableNFT();

        for(uint8 i = 0; i < amountToMint; i++) {
            token.safeMint(msg.sender);
        }        
    }

    function offerMany(uint256[] calldata tokenIds, uint256[] calldata prices) external nonReentrant {
        require(tokenIds.length > 0 && tokenIds.length == prices.length);
        for (uint256 i = 0; i < tokenIds.length; i++) {
            _offerOne(tokenIds[i], prices[i]);
        }
    }

    function _offerOne(uint256 tokenId, uint256 price) private {
        require(price > 0, "Price must be greater than zero");

        require(
            msg.sender == token.ownerOf(tokenId),
            "Account offering must be the owner"
        );

        require(
            token.getApproved(tokenId) == address(this) ||
            token.isApprovedForAll(msg.sender, address(this)),
            "Account offering must have approved transfer"
        );

        offers[tokenId] = price;

        amountOfOffers++;

        emit NFTOffered(msg.sender, tokenId, price);
    }

    function buyMany(uint256[] calldata tokenIds) external payable nonReentrant {
        uint256 fundsForPurchases = msg.value;
        for (uint256 i = 0; i < tokenIds.length; i++) {
            uint256 pricePaid = _buyOne(tokenIds[i], fundsForPurchases);
            fundsForPurchases -= pricePaid;
        }
    }

    function _buyOne(uint256 tokenId, uint256 fundsForPurchase) private returns (uint256 pricePaid) {       
        uint256 priceToPay = offers[tokenId];
        require(priceToPay > 0, "Token is not being offered");

        require(fundsForPurchase >= priceToPay, "Amount paid is not enough");

        amountOfOffers--;

        // pay seller
        payable(token.ownerOf(tokenId)).sendValue(priceToPay);

        // transfer from seller to buyer
        token.safeTransferFrom(token.ownerOf(tokenId), msg.sender, tokenId);

        emit NFTBought(msg.sender, tokenId, priceToPay);

        return priceToPay;
    }    

    receive() external payable {}
}
