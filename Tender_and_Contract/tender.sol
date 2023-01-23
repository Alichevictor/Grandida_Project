// SPDX-License-Identifier: MIT

/* This is a smart contract for Tender DApp. It consists of two contracts - 
   tender, and tenderFactory - which is used to declare instances of the 'tender'
   contract.
*/

pragma solidity^0.8.17;

contract Tender {

    event done(address indexed addy, string message);
    string public data;
    // uint public fees = 0.3;
    address payable public manager;
    bool isActive;
    bool public awaiting;
    bool public complete;
    
    /**
    *@dev data - requirements of the tender/ terms and coditions 
    *@dev manager - address of the manager/creator of the tender contract
    *@dev complete - status of whether the tender has BEEN AWARDED
    *@dev pending - awaiting bid payment
    */
    struct Bid {
        address bidder;
        uint256 bidAmount;
        string bid;
    }
    /* struct Bid is a type to hold the details of a bid made - containing
       the address of the bidder, the amount that the bid is made at, and the
       proposal of the bidder (bid).
    */
    struct hiddenBid {
        uint256 ID; // use bytes32 and hash the ID
        uint bidAmount;
        string bid;
    }

   
    
    /**
    *@dev bids - array of bidders id
    *@dev hiddenBids - array of bids with address to mitigate bais
    *@dev winner - finalized bidder 
    *@dev winIndex - id of winner in bid[i]
    */
    Bid[] private bids;
    hiddenBid[] public hiddenBids;
    Bid public winner;
    uint256 public winIndex;
    uint256 bid_amount;
    /* 1.bids consists of all the bids and is made private to ensure no bias.
       2.hiddenBids is the array of structures that contain bids without their addresses, for 
         the purpose of the govt choosing a bid
       3.winner consists of the address of the winning bidder and winIndex contains the index
    */
   // getlist of all bids with description  made
   // buttons and functions
    /**
    * @dev initial owner of contract
    */
    constructor()  {
        manager = payable (msg.sender);
    }
    modifier onlyowner()
     {
         require(msg.sender==manager,"Access Denied");
         _;
     }
    
    /**
    * @dev tender() creates new tenders in  tender Factory
    * @param description - details of tender demands
    * @param creator - address of tender creator
    * create new instance of the tender contract.
    */
    function CreateTender(string memory description, address payable creator) public virtual
    {
        require(!isActive, "Auction still active");
        manager = creator;
        data = description;
        isActive = true;
        emit done(manager, "Created a tender");
    }
    
    /* This function returns the details of the bidder, bidAmount and bid(proposal)
       only after the tender has been awarded, to ensure transparency in the system.
    */
    function getBidSummary(uint index) public view returns (address, uint, string memory) {
        return (
            bids[index].bidder,
            bids[index].bidAmount,
            bids[index].bid
        );
    }
    
    //function () payable external {}
    /* This function is used to let a bidder make a bid, it creates a temporary instance
       of Bid and hiddenBid and initialised them and pushes them into the respective arrays.
    */
    function makeBid(uint256 bidAmount, string memory desc)  public
    {  require(!(msg.sender==manager));
       require(!complete);
       
        Bid memory newBid = Bid({
            bidder : msg.sender,
            bidAmount : bidAmount,
            bid : desc
        });
        bids.push(newBid);
        hiddenBid memory newhiddenBid = hiddenBid({
            ID : bids.length, //hash ID to make it unique
            bidAmount : bidAmount,
            bid : desc
        });
        hiddenBids.push(newhiddenBid);
        //approve(newBid.bidder, manager);
        emit done(msg.sender,"Created a new bid");
    }

    /**@dev finalizeBid is used to award the bid by passing an argument of the index of the bid,
       It is a payable function, the sender of the call passes some ether to the contract
       the bidAmount is sent to the chosen bidder, and the balance is sent back to the 
       manager of the tender.
    */
    function finalizeBid(uint index) public onlyowner() {
        require(!complete);
        winner = bids[index];
        winIndex = index;
        bid_amount = winner.bidAmount;
        awaiting = true;
        emit done(winner.bidder,"Authorized");   
    }
    
    function payBid(uint256 _amt) external payable {
        require(msg.sender == winner.bidder, "Not authorized bidder");
        require(msg.value >= bid_amount, "insufficient funds!");
        if (_amt != bid_amount){
            revert("value is not what was agreed");
        }
        awaiting = false;
        complete = true;
        //isActive = false;
        emit done(msg.sender, "Payment made");
    }

    function withdrawFees(address payable reciever) public onlyowner(){
        reciever.transfer(address(this).balance);
    }

    function recievePay() public onlyowner() {
        address(this).balance - (bid_amount * 3 / 100);
        manager.transfer(address(this).balance);
        emit done(msg.sender, "Claimed payment");
    }

    function getSummary() public view returns (address, string memory, uint) {
        return(manager,
        data,
        bids.length);
    }
    function getBidCount() public view returns (uint ID) {
        return bids.length;
    }
    

    function verifyManager() public view returns (bool) {
        return(manager==msg.sender);
    }
    
    function status() public view returns(string memory, bool, string memory, bool)
    {
        string memory stats = "complete: ";
        string memory stats2 = "Awating: ";
        return (stats, complete, stats2, awaiting);
    }

    function getcontractBalance() public view returns (uint){
        return address(this).balance;
    }
}

