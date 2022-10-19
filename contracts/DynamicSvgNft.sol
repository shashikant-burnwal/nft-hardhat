//DynamicSvgNft.sol
//SPDX-License-Identifier:MIT

pragma solidity ^0.8.7;


import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "base64-sol/base64.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";


contract DynamicSvgNft is ERC721 {
    //mint
    //Store our SVG Information somewhere
    //Some logic to say "Show X Image" or show Y image

    uint256 private s_tokenCounter;
    string private s_lowImageURI;
    string private s_highImageURI;
    string private constant base64EncodedSvgPrefix="data:image/svg+xml;base64,";
    AggregatorV3Interface internal immutable i_priceFeed;
    mapping(uint256=>int256) private s_tokenIdToHighValues;

    event CreatedNFT (uint256 indexed tokenId, int256 highValue);

    constructor(address priceFeedAddress, string memory lowSvg, string memory highSvg)ERC721("Dynamic SVG NFT", "DSN"){
        s_tokenCounter=0;
        s_lowImageURI = svgToImageURI(lowSvg);
        s_highImageURI =svgToImageURI(highSvg);
        i_priceFeed=AggregatorV3Interface(priceFeedAddress);


    }

    function svgToImageURI(string memory svg) public pure returns (string memory) {
        string memory baseURL ="data:image/svg+xml;base64,";
        string memory svgBase64Encoded=Base64.encode(bytes(string(abi.encodePacked(svg))));
        return string(abi.encodePacked(baseURL,svgBase64Encoded));
    }

    function mintNft(int256 highValue) public {
        s_tokenIdToHighValues[s_tokenCounter]=highValue;
        _safeMint (msg.sender, s_tokenCounter);
        s_tokenCounter+=1;
        emit CreatedNFT(s_tokenCounter, highValue);
    }

    function _baseURI() internal pure override returns (string memory){
        return "data:application/json;base64,";
    }

    function tokenURI (uint256 tokenId) public view virtual override returns (string memory){
        require (_exists(tokenId),"URI query for nonexistent token");
         (, int256 price, , , ) = i_priceFeed.latestRoundData();
         string memory imageURI =s_lowImageURI;
         if (price>=s_tokenIdToHighValues[tokenId]){
            imageURI=s_highImageURI;
         }

         //create tokenURI with metadata

         return string(abi.encodePacked(_baseURI(),
         Base64.encode(bytes(
            abi.encodePacked('{"name":"',
                                name(), // You can add whatever name here
                                '", "description":"An NFT that changes based on the Chainlink Feed", ',
                                '"attributes": [{"trait_type": "coolness", "value": 100}], "image":"',
                                imageURI,
                                '"}')
            
         ))
         ));



    }


     function getLowSVG() public view returns (string memory) {
        return s_lowImageURI;
    }

    function getHighSVG() public view returns (string memory) {
        return s_highImageURI;
    }

    function getPriceFeed() public view returns (AggregatorV3Interface) {
        return i_priceFeed;
    }

    function getTokenCounter() public view returns (uint256) {
        return s_tokenCounter;
    }
}