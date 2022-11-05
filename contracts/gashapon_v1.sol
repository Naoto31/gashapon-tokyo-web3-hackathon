//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "hardhat/console.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract Gashapon_V1 is ERC721URIStorage {

    address payable owner;

    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;
    Counters.Counter private _itemsSold;

    uint256 listPrice = 0.0005 ether; // this is needed when users list their own NFT to market place

    constructor() ERC721("Gashapon_V1", "GASHA") {
        owner = payable(msg.sender);
    }

    struct ListedToken {
        uint256 tokenId;
        address payable owner;
        address payable seller;
        uint256 price;
        bool currentlyListed;   
    }

    // This mapping maps tokenId to token info and is helpful when retrieving details about a tokenId
    mapping(uint256 => ListedToken) private idToListedToken;

    // update listing price, without this you cannot increase it after deploying smart contract
    function updateListPrice(uint256 _listPrice) public payable {
       require(owner == msg.sender, "Only owner can update listing price");
        listPrice = _listPrice;
    }

    // to check current listing price
    function getListPrice() public view returns (uint256) {
        return listPrice;
    }

    // get latest token
    function getLatestIdToListedToken() public view returns (ListedToken memory) {
        uint256 currentTokenId = _tokenIds.current();
        return idToListedToken[currentTokenId];
    }

    // get certain token by tokenId
    function getListedForTokenId(uint256 tokenId) public view returns (ListedToken memory) {
        return idToListedToken[tokenId];
    }

    // get current tokenId
    function getCurrentToken() public view returns (uint256) {
        return _tokenIds.current();
    }

    function createToken(string memory tokenURI, uint256 price) public payable returns (uint) {
        require(msg.value == listPrice, "Send enough ether to list");
        require(price > 0, "Make sure the price isn't negative");

        _tokenIds.increment();
        uint256 currentTokenId = _tokenIds.current();
        _safeMint(msg.sender, currentTokenId); // this one is already implemented in ERC721

        _setTokenURI(currentTokenId, tokenURI);

        createListedToken(currentTokenId, price);

        return currentTokenId;
    }

    // this function is called inside smart contract, so it is 'private' function
    function createListedToken(uint256 tokenId, uint256 price) private {
        idToListedToken[tokenId] = ListedToken(
            tokenId,
            payable(address(this)),
            payable(msg.sender),
            price,
            true // this is true for default to make it simple, but we can make it optional in the future
        );

        _transfer(msg.sender, address(this), tokenId); // transfer NFT's ownership to this smart contract, otherwise we need approve function
    }

    function getAllNFTs() public view returns(ListedToken[] memory) {
        uint nftCount = _tokenIds.current();

        ListedToken[] memory tokens = new ListedToken[](nftCount);

        uint currentIndex = 0;

        for (uint i = 0; i < nftCount; i++) {
            uint currentId = i + 1;
            ListedToken storage currentItem = idToListedToken[currentId];
            tokens[currentIndex] = currentItem;
            currentIndex += 1;
        }

        return tokens;
    }

    function getMyNFTs() public view returns (ListedToken[] memory) {
        uint totalItemCount = _tokenIds.current();
        uint itemCount = 0;
        uint currentIndex = 0;
        uint currentId;

        //Important to get a count of all the NFTs that belong to the user before we can make an array for them
        for(uint i=0; i < totalItemCount; i++)
        {
            if(idToListedToken[i+1].owner == msg.sender || idToListedToken[i+1].seller == msg.sender){
                itemCount += 1;
            }
        }

        //Once you have the count of relevant NFTs, create an array then store all the NFTs in it
        ListedToken[] memory items = new ListedToken[](itemCount);
        for(uint i=0; i < totalItemCount; i++) {
            if(idToListedToken[i+1].owner == msg.sender || idToListedToken[i+1].seller == msg.sender) {
                currentId = i+1;
                ListedToken storage currentItem = idToListedToken[currentId];
                items[currentIndex] = currentItem;
                currentIndex += 1;
            }
        }
        return items;
    }

    function executeSale(uint256 tokenId) public payable {
        uint price = idToListedToken[tokenId].price;
        require(msg.value == price, "Please submit the asking price for the NFT in order to purchase");

        address seller = idToListedToken[tokenId].seller;

        idToListedToken[tokenId].currentlyListed = true; // you can change this to false so it won't be displayed on the market place. 
        idToListedToken[tokenId].seller = payable(msg.sender);

        _transfer((address(this)), msg.sender, tokenId);

        approve(address(this), tokenId); // you can actually approve that the bought NFT is owned by this contract, so we can easily put in sales again.

        payable(owner).transfer(listPrice); // smart contract owner gets listing price (commision)
        payable(seller).transfer(msg.value); // seller get money 
    }
}