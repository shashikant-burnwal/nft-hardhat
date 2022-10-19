// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

 
//errors

error RandomIpfsNft__RangeOutOfBounds();
error RandomIpfsNft__NeedMoreETHSent();
error RandomIpfsNft__TransferFailed();
error RandomIpfsNft__AlreadyInitialized();

contract RandomIpfsNft is VRFConsumerBaseV2, ERC721URIStorage,Ownable {
    //when we mint an NFT, we will trigger a Chainlink VRF call to get us a random number
    //using that number, we will get a random NFT
    //Pug, Shiba Inu, St. Bernard
    //Pug super rare, Shiba sort of rare and St. Bernard common

    //users have to pay to mint an NFT

    //the owner of the contract can withdraw the ETH


    //Type Variables
    enum Breed{
        PUG,
        SHIBA_INU,
        ST_BERNARD
    }

    //Chainlink VRF Variables

    VRFCoordinatorV2Interface private immutable i_vrfCoordinatorV2;
    uint64 private immutable i_subscriptionId;
    bytes32 private immutable i_gasLane;
    uint32 private immutable i_callbackGasLimit;
    uint16 private constant REQUEST_CONFIRMATIONS =3;
    uint32 private constant NUM_WORDS =1;
    
//VRF Helper
 mapping (uint256=>address) public s_requestIdToSender;


 //NFT Variables

 uint256 private s_tokenCounter;
 uint256 internal constant MAX_CHANCE_VALUE=100;
 string[] internal s_dogTokenUris;
 uint256 internal immutable i_mintFee;
 bool private s_initialized;


//Events
   event NftRequested(uint256 indexed requestId, address requester);
   event NftMinted(Breed breed, address minter);

    constructor(address vrfCoordinatorV2, uint64 subscriptionId,bytes32 gasLane, uint256 mintFee, uint32 callbackGasLimit,string[3] memory dogTokenUris  ) VRFConsumerBaseV2(vrfCoordinatorV2) ERC721("Random IPFS NFT", "RIN"){
        i_vrfCoordinatorV2=VRFCoordinatorV2Interface(vrfCoordinatorV2);
        i_subscriptionId=subscriptionId;
      i_gasLane=gasLane;
      i_mintFee=mintFee;
       i_callbackGasLimit=callbackGasLimit;
       _initializeContract(dogTokenUris);
       
    }

    function requestNft() public payable returns (uint256 requestId) {

        if(msg.value<i_mintFee){
            revert  RandomIpfsNft__NeedMoreETHSent();
        }


        requestId = i_vrfCoordinatorV2.requestRandomWords(
            i_gasLane,
            i_subscriptionId,
            REQUEST_CONFIRMATIONS,
            i_callbackGasLimit,
            NUM_WORDS
        );

        s_requestIdToSender[requestId]=msg.sender;
        emit NftRequested(requestId,msg.sender);

         

    }

    function fulfillRandomWords (uint256 requestId, uint256[] memory randomWords) internal override {
        address dogOwner = s_requestIdToSender[requestId];
        uint256 newItemId=s_tokenCounter;
        s_tokenCounter=s_tokenCounter+1;
        uint256 moddedRng =randomWords[0]%MAX_CHANCE_VALUE;

        Breed dogBreed= getBreedFromModdedRng(moddedRng);
        _safeMint(dogOwner,newItemId);
        _setTokenURI (newItemId, s_dogTokenUris[uint256(dogBreed)]);
        emit NftMinted(dogBreed,dogOwner);

        

    }

    function _initializeContract(string[3] memory dogTokenUris) private {
        if (s_initialized){
            revert RandomIpfsNft__AlreadyInitialized();

        }
        s_dogTokenUris=dogTokenUris;
        s_initialized=true;
    }

    //withdraw function
    function withdraw() public onlyOwner{
        uint256 amount=address(this).balance;
        (bool success,)=payable(msg.sender).call{value:amount}("");
        if(!success){revert RandomIpfsNft__TransferFailed(); }

    }

    function getBreedFromModdedRng(uint256 moddedRng) public pure returns(Breed){
        //PUG 0-9 (10%)
        //Shiba Inu 10-39 (30%)
        //St.Bernard 40-99 (100%)

        uint256 cumulativeSum=0;
        uint256[3] memory chanceArray=getChanceArray();
        for (uint256 i=0;i<chanceArray.length;i++){
            if (moddedRng>=cumulativeSum && moddedRng<chanceArray[i]){
                return Breed(i);
            }
            cumulativeSum=chanceArray[i];
        }

         revert RandomIpfsNft__RangeOutOfBounds();
    }

    function getChanceArray() public pure returns (uint256[3] memory){
        return [10,40,MAX_CHANCE_VALUE];
    }


     function getTokenCounter() public view returns (uint256) {
        return s_tokenCounter;
    }

    function getMintFee() public view returns (uint256) {
        return i_mintFee;
    }

    function getDogTokenUris(uint256 index) public view returns (string memory) {
        return s_dogTokenUris[index];
    }

      function getInitialized() public view returns (bool) {
        return s_initialized;
    }


}