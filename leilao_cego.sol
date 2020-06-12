// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.4.22 <0.7.0;
// 0.5.16+commit.9c3226ce
contract Licitation_Auction {
    
    address payable beneficiary;
    uint tax_value;
    uint biddingEnd;
    uint revealEnd;
    bool ended = false;
    address public winner;
    uint n_participants = 0;
    uint minimum_offer;
    uint public lowest_bid;
    uint start_price;
    address payable public current_winner;
    
    
    struct Participant {
        bool auth;
        bool proposed;
        bytes32 proposal;
        uint tax;
        bool revealed;
        uint actual_value;
    }
    
    
    mapping(address => Participant) public participants;
    mapping(address => uint) pendingReturns;
    
    modifier ownerOnly() {
        require(msg.sender==beneficiary);
        _;
    }
    
    modifier onlyBefore(uint _time) { require(now < _time); _; }
    modifier onlyAfter(uint _time) { require(now > _time); _; }
    
    event AuctionEnded(address current_winner, uint lowest_bid);
    
    constructor(
            uint _biddingTime,
            uint _revealTime,
            uint _tax_value,
            uint _minimal_offer,
            uint _start_price
        ) public {
            tax_value = _tax_value;
            beneficiary = msg.sender;
            biddingEnd = now + _biddingTime;
            revealEnd = biddingEnd + _revealTime;
            minimum_offer = _minimal_offer;
            start_price = _start_price;
            lowest_bid = _start_price;
        }
        
    // create hash bid    
    // function encodeBid(uint _value, uint _cnpj) onlyBefore(biddingEnd) public {
    //     test_encode = keccak256(abi.encodePacked(_value, _cnpj));
    // }
        
    function authtorize(address _participant) ownerOnly onlyBefore(biddingEnd) public {
        participants[_participant].auth = true;
        n_participants += 1;
    }
    
    function bid(bytes32 _bid) onlyBefore(biddingEnd) payable public{
        require(!participants[msg.sender].proposed);
        require(participants[msg.sender].auth);
        require(msg.value == tax_value);
        
        participants[msg.sender].proposal = _bid;
        participants[msg.sender].proposed = true;
        participants[msg.sender].tax = msg.value;
        
    }
    
    function withdraw() onlyBefore(biddingEnd) public{
        require(participants[msg.sender].proposed);
        require(participants[msg.sender].auth);
        
        participants[msg.sender].proposed = false;
        participants[msg.sender].proposal = 0;
        
        msg.sender.transfer(participants[msg.sender].tax);
        participants[msg.sender].tax = 0;
    }
    
    
    function reveal(uint _value, uint _cnpj) public onlyAfter(biddingEnd) onlyBefore(revealEnd){
        require(participants[msg.sender].proposed);
        require(participants[msg.sender].auth);
        require(participants[msg.sender].proposal == keccak256(abi.encodePacked(_value, _cnpj)));
        
        if (_value>minimum_offer && _value<lowest_bid){
            if (lowest_bid != start_price){
                current_winner.transfer(participants[current_winner].tax);
                participants[current_winner].tax = 0;
                participants[current_winner].proposed = false;
            }
            lowest_bid = _value;
            current_winner = msg.sender;
        }else{
            require(participants[msg.sender].proposed);
            participants[msg.sender].proposed = false;
            participants[msg.sender].proposal = 0;
            msg.sender.transfer(participants[msg.sender].tax);
            participants[msg.sender].tax = 0;
        }

    } 
    
    function auctionEnd() public ownerOnly onlyAfter(revealEnd)
    {
        require(!ended);
        emit AuctionEnded(current_winner, lowest_bid);
        winner = current_winner;
        ended = true;
        beneficiary.transfer(address(this).balance);

    }
    
}


