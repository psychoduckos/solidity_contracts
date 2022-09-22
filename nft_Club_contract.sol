// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

contract club {
    NFT nft;
    TOKEN token;
    ColllectionName specialNFT;
    struct member {
        address _address;
        bool adult;
    }

    mapping(address => member) public members;

    member[] arrayMembers;

    uint index;

    constructor( string  memory uri) {
        nft = new NFT();
        specialNFT = new ColllectionName();
        token = new TOKEN();
        members[msg.sender] = member({_address: msg.sender, adult: true});

        arrayMembers.push(members[msg.sender]);

        specialNFT.safeMint(msg.sender, uri);
        token.mint(msg.sender, 100);
    }

    function nft_address() public view returns (address) {
        return address(nft);
    }

    function speshl_nft_address() public view returns (address) {
        return address(specialNFT);
    }

    modifier isAdult() {
        require(members[msg.sender].adult == true);
        _;
    }

    function addMember(
        address _address,
        bool _adult,
        string  memory uri
    ) public isAdult {
        require(
            members[_address]._address == address(0),
            "already existing user"
        );
        members[_address] = member({_address: _address, adult: _adult});
        arrayMembers.push(members[_address]);
        if(keccak256(abi.encodePacked(uri)) == keccak256(abi.encodePacked(""))){
            nft.safeMint(_address);
        } else {
            specialNFT.safeMint(msg.sender, uri);
        }
        token.mint(_address, 100);
    }

    function deleteMember(address _address) public isAdult {
        members[_address] = member({_address: address(0), adult: false});
        //из массива не удаляется
        nft.safeMint(_address);
    }

    function returnMemberByAddress(address _address)
        public
        view
        returns (member memory)
    {
        return members[_address];
    }

    function returnArray() public view returns (member[] memory) {
        return arrayMembers;
    }
}