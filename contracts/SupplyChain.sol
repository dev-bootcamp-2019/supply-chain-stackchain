pragma solidity ^0.4.23;

contract SupplyChain {

    /* set owner */
    address owner;

    /* Add a variable called skuCount to track the most recent sku # */
    uint public skuCount;

    /* Add a line that creates a public mapping that maps the SKU (a number) to an Item.
      Call this mappings items
    */
    mapping(uint => Item) items;

    /* Add a line that creates an enum called State. This should have 4 states
      ForSale
      Sold
      Shipped
      Received
      (declaring them in this order is important for testing)
    */
    enum State { ForSale, Sold, Shipped, Received }

    /* Create a struct named Item.
      Here, add a name, sku, price, state, seller, and buyer
      We've left you to figure out what the appropriate types are,
      if you need help you can ask around :)
    */
    struct Item {
        string name;
        uint sku;
        uint price;
        State state;
        address seller;
        address buyer;
    }

    /* Create 4 events with the same name as each possible State (see above)
      Each event should accept one argument, the sku*/
    event ForSale(uint sku);
    event Sold(uint sku);
    event Shipped(uint sku);
    event Received(uint sku);

    /* Create a modifer that checks if the msg.sender is the owner of the contract */
    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can perform this action");
        _;
    }

    modifier verifyCaller (address _address) {require (msg.sender == _address, "You can't perform this action"); _;}
    modifier paidEnough(uint _price) {require(msg.value >= _price, "Insuficient amount"); _;}
    modifier checkValue(uint _sku) {
        //refund them after pay for item (why it is before, _ checks for logic before func)
        _;
        uint amountToRefund = msg.value - items[_sku].price;
        items[_sku].buyer.transfer(amountToRefund);
    }

    /* For each of the following modifiers, use what you learned about modifiers
    to give them functionality. For example, the forSale modifier should require
    that the item with the given sku has the state ForSale. */
    modifier forSale(State _state) {require(_state == State.ForSale, "Item is not ForSale"); _;}
    modifier sold(State _state) {require(_state == State.Sold, "Item is not Sold"); _;}
    modifier shipped(State _state) {require(_state == State.Shipped, "Item is not Shipped"); _;}
    modifier received(State _state) {require(_state == State.Received, "Item is not Received"); _;}


    constructor() public {
      /* Here, set the owner as the person who instantiated the contract
        and set your skuCount to 0. */
        owner = msg.sender;
        skuCount = 0;
    }

    function addItem(string _name, uint _price) public {
        emit ForSale(skuCount);
        items[skuCount] = Item({name: _name, sku: skuCount, price: _price, state: State.ForSale, seller: msg.sender, buyer: 0});
        skuCount = skuCount + 1;
    }

    /* Add a keyword so the function can be paid. This function should transfer money
      to the seller, set the buyer as the person who called this transaction, and set the state
      to Sold. Be careful, this function should use 3 modifiers to check if the item is for sale,
      if the buyer paid enough, and check the value after the function is called to make sure the buyer is
      refunded any excess ether sent. Remember to call the event associated with this function!*/

    function buyItem(uint sku)
      public
      payable
      forSale(items[sku].state)
      paidEnough(items[sku].price)
      checkValue(sku)
    {
        // ajust storage data (dont sell same item twice)
        Item storage _item = items[sku];
        _item.buyer = msg.sender;
        _item.state = State.Sold;
        // send money to the item seller (the owner of item)
        _item.seller.transfer(_item.price);
        emit Sold(sku);
    }

    /* Add 2 modifiers to check if the item is sold already, and that the person calling this function
    is the seller. Change the state of the item to shipped. Remember to call the event associated with this function!*/
    function shipItem(uint sku)
      public
      sold(items[sku].state)
      verifyCaller(items[sku].seller)
    {
        // ajust storage data (dont ship same item twice)
        Item storage _item = items[sku];
        _item.state = State.Shipped;
        emit Shipped(sku);
    }

    /* Add 2 modifiers to check if the item is shipped already, and that the person calling this function
    is the buyer. Change the state of the item to received. Remember to call the event associated with this function!*/
    function receiveItem(uint sku)
      public
      shipped(items[sku].state)
      verifyCaller(items[sku].buyer)
    {
        // ajust storage data (finishs the supply transaction)
        Item storage _item = items[sku];
        _item.state = State.Received;
        emit Received(sku);
    }

    /* We have these functions completed so we can run tests, just ignore it :) */
    function fetchItem(uint _sku) public view returns (string name, uint sku, uint price, uint state, address seller, address buyer) {
        name = items[_sku].name;
        sku = items[_sku].sku;
        price = items[_sku].price;
        state = uint(items[_sku].state);
        seller = items[_sku].seller;
        buyer = items[_sku].buyer;
        return (name, sku, price, state, seller, buyer);
    }

}
