// SPDX-License-Identifier: MIT
//Proposal for improvements to ERC-8048
/// Copyright (c) 2026 _zero
pragma solidity ^0.8.24;
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v5.7.0/contracts/access/Ownable.sol";

interface IOwnable {
    function owner() external view returns (address);
}

contract attach8048 is Ownable{

    address public mainnft;

    constructor(address main,address creator)  Ownable(creator) {
        mainnft = main;
        
    }

    //nft id => datatype(image,name...) => data
    mapping(uint => mapping(string =>bytes)) public metadatas;
    //nft id =>lock flag
    mapping(uint => bool) public nftdatalock;

    event MetadataSet(uint256 indexed tokenId, string indexed indexedKey, string key, bytes value);
    event MetadataUpdate(uint256 tokenId);

    function setMetadata(uint256 tokenId, string calldata key,bytes memory registerdata) public {
       
        require(msg.sender == IOwnable(mainnft).owner());
        require(nftdatalock[tokenId] == false);
        metadatas[tokenId][key] = registerdata;
        
        emit MetadataSet(tokenId, key, key, registerdata);

        if (metadatas[tokenId]["metadata_uri"].length == 0 && keccak256(bytes(key)) == keccak256(bytes("svg"))) {
            bytes memory temp = bytes('{"image":"onchain:image/svg+xml?key=svg"}');
            metadatas[tokenId]["metadata_uri"] = temp;
            emit MetadataSet(tokenId, "metadata_uri", "metadata_uri", temp);
            
        }

        emit MetadataUpdate(tokenId);
        
    }

    

    function metadata(uint256 tokenId, string calldata key) public view returns (bytes memory){
        if (keccak256(bytes(key)) == keccak256(bytes("full_onchain_image"))){
            if ( metadatas[tokenId]["png"].length > 0 ||metadatas[tokenId]["jpeg"].length > 0 || metadatas[tokenId]["svg"].length > 0 ) {
            return bytes("true");
        }
        }
        return metadatas[tokenId][key];
    }

    //Only on-chain data is subject to locking.
    function setNFTDataLock(uint nftid) public {
        require(msg.sender == IOwnable(mainnft).owner());
        nftdatalock[nftid] = true;
    }

     function supportsInterface(bytes4 interfaceID) public pure returns (bool flag){
        if(interfaceID ==  0xdf670be1 || interfaceID == 0x01ffc9a7 || interfaceID ==  type(IERC8048TokenMetadataLockandTypesLists).interfaceId){
            return true;
        }
    }
}

contract attach8048Creator {

    mapping(address => attach8048) public attach8048lists;

    mapping(address => bool) public attach8048locklists;

    event CreateAttach(address indexed mainnft, attach8048 indexed attachcontract, address indexed creator);

   function createAttach8048 (address MainNFT) public returns (attach8048 tokenAddress){
        require(msg.sender == IOwnable(MainNFT).owner());
        require(attach8048locklists[MainNFT] == false);

        //If it conflicts with other registries, the latest one takes precedence.
        
        attach8048 atta = new attach8048(MainNFT,msg.sender);
        attach8048lists[MainNFT] = atta;

        emit CreateAttach(MainNFT, atta, msg.sender);
        
        return atta;
    }

    function lockNFT(address MainNFT) public {
        require(msg.sender == IOwnable(MainNFT).owner());
        attach8048locklists[MainNFT] = true;
    }
}

interface IERC8048TokenMetadataLockandTypesLists {
    function setNFTDataLock(uint nftid) external;
}
