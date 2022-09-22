// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./Nft.sol";
import "./contracts/token/ERC721/IERC721Receiver.sol";


contract NftStaking {
    NFT public parentNFT;

    struct Stake {
        uint256 tokenId;
        uint256 timestamp;
    }

    // map staker address to stake details
    mapping(address => Stake) public stakes;

    // map staker to total staking time 
    mapping(address => uint256) public stakingTime;    

    constructor(address _addr) {
        parentNFT = NFT(address(_addr)); // Change it to your NFT contract addr
    }

    function stake(uint256 _tokenId) public {
        stakes[msg.sender] = Stake(_tokenId, block.timestamp); 
        parentNFT.safeTransferFrom(msg.sender, address(this), _tokenId);
    } 

    function unstake() public {
        parentNFT.safeTransferFrom(address(this), msg.sender, stakes[msg.sender].tokenId);
        stakingTime[msg.sender] += (block.timestamp - stakes[msg.sender].timestamp);
        delete stakes[msg.sender];
    }      

    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4){
        return bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"));
    }


}