//SPDX-License-Identifier: UNLICENSED

pragma solidity >0.7.0 <0.9.0;

contract Auction {
    address payable public auctioneer;
    address payable public highestBidder;
    uint256 public highestBid;

    uint256 public initialPrice;
    uint256 private startBlock;
    uint256 private endBlock;
    uint256 public bidIncrement;

    enum auc_state {
        running,
        ended,
        cancelled
    }

    auc_state public auctionState;

    mapping(address => uint256) private bids;

    event loghighestBid(
        address indexed highestBidder,
        uint256 indexed highestBid
    );

    event AuctionCancelled();

    constructor(
        address payable _auctioneer,
        uint256 _startBlock,
        uint256 _endBlock,
        uint256 _initialPrice,
        uint256 _bidIncrement
    ) {
        require(_startBlock <= _endBlock, "Wrong startBlock or endBlock");
        require(_initialPrice > 0, "initial Price must be greater than 0");

        auctioneer = _auctioneer;

        startBlock = _startBlock;
        endBlock = _endBlock;
        initialPrice = _initialPrice;
        bidIncrement = _bidIncrement;
        auctionState = auc_state.running;
    }

    function placeBid() public payable notOwner onlyRunningAuction {
        // front end will get the current bet and give only required amount to the function

        uint256 currentBet; //getting the current bet amount by the better

        currentBet = bids[msg.sender];

        require(
            msg.value + currentBet >= initialPrice,
            "Cannot bet less than the price"
        );

        require(
            (currentBet + msg.value) > (bids[highestBidder] + bidIncrement),
            "Bid not high enough"
        );

        bids[msg.sender] += msg.value;

        highestBidder = payable(msg.sender);
        highestBid = msg.value;

        currentBet = 0;
        emit loghighestBid(highestBidder, highestBid);
    }

    function withdraw() public {
        require(
            auctionState == auc_state.ended ||
                auctionState == auc_state.cancelled ||
                block.number > endBlock,
            "Auction still running"
        );
        uint256 withdrawAmount;
        address payable withdrawAccount;

        if (auctionState == auc_state.cancelled) {
            withdrawAccount = payable(msg.sender);
            withdrawAmount = bids[msg.sender];
        } else {
            if (msg.sender == auctioneer) {
                withdrawAccount = auctioneer;
                withdrawAmount = bids[highestBidder];
            } else if (msg.sender == highestBidder) {
                withdrawAccount = highestBidder;
                withdrawAmount = bids[highestBidder] - highestBid;
            } else {
                withdrawAccount = payable(msg.sender);
                withdrawAmount = bids[msg.sender];
            }
        }
        withdrawAccount.transfer(withdrawAmount);
        bids[withdrawAccount] = 0;
    }

    function cancelAuction() public onlyRunningAuction onlyOwner {
        auctionState = auc_state.cancelled;
        emit AuctionCancelled();
    }

    function getBidAmount(address _bidAccount) public view returns (uint256) {
        return bids[_bidAccount];
    }

    function changeAuctionStateToEnded() public onlyRunningAuction onlyOwner {
        auctionState = auc_state.ended;
    }

    function getHighestBidder() public view returns (address) {
        require(
            auctionState == auc_state.ended || block.number >= endBlock,
            "Cannot access the function before end of auction"
        );
        return highestBidder;
    }

    modifier onlyOwner() {
        require(msg.sender == auctioneer, "Only Owner can access the function");
        _;
    }

    modifier notOwner() {
        require(msg.sender != auctioneer, "Owner cannot access this function");
        _;
    }
    modifier onlyRunningAuction() {
        require(
            auctionState == auc_state.running,
            "Function can only be accesses while the auction is running"
        );
        _;
    }
}
