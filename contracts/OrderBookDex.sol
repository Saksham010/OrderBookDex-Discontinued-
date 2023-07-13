pragma solidity 0.8.14;

interface ERC20 {
    function approve(address _spender, uint256 _value) external returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) external returns (bool success);
    function transfer(address _to, uint256 _value) external returns (bool success);

}

contract DexBook{
    // Type of order
    enum orderType{
        buy,
        sell
    }

    struct Order{
        orderType _orderType;
        address _caller;
        address _tokenfrom;
        address _tokento;
        uint256 _amount;
        uint256 _price;
    }


    // Seller -> token -> amount
    // mapping (address => mapping(address=>uint256)) sellOrder;
    // mapping(address => mapping(address => uint256)) buyOrder; //Buyer -> token -> amount

    // Order id => 
    mapping(uint256=>Order) public order;
    mapping(uint256 => bool) orderStatus;

    // Active sell orders
    uint256[] activeSellOrders;
    // Active buy orders
    uint256[] activeBuyOrders;
    uint256 orderId;



    // Check if the order hits
    function resolveOrder(orderType _orderType, address token, uint256 amount, uint256 price,uint256 sellId)public returns(bool){

        if(_orderType == orderType.sell){
            
            for(uint i; i < activeBuyOrders.length;i++){

                // Current order id
                uint256 buyId = activeBuyOrders[i];

                // Check if the token and limit price
                if( order[buyId]._price == price && order[buyId]._token == token){

                    // If the buying amount is smaller
                    if(order[buyId]._amount < order[sellId]._amount){

                        // Update the sell order amount
                        order[sellId]._amount = order[sellId]._amount - order[buyId]._amount; 

                        // Transfer token to the buyer
                        // payable(order[buyId]._caller).transfer(order[])
                        

                    }
                    
                }

            }
        }
        
    }


    // Put a limit order (type = 1=> sell, type 0 => buy)
    function limitOrder(uint256 _type,address tokenfrom,address tokento,uint256 amount, uint256 price) public returns(uint256) {

        // Check if type is 1 or 0 or not
        require(_type ==0 || _type == 1, "Invalid type value");

        // Increment counter
        orderId++;

        if(_type == orderType.sell){
            // Store order
            order[orderId] = Order(orderType.sell,msg.sender,tokenfrom,tokento,amount,price);

            // Push to active sell orders
            activeSellOrders.push(orderId);

        
        }
        else(
            // Store order
            order[orderId] = Order(orderType.buy,msg.sender,tokenfrom,tokento,amount,price);

            // Push to active sell orders
            activeBuyOrders.push(orderId);
            
        )

        // Set the order status
        orderStatus[orderId] = true;

        // Approve token transfer 
        bool success = ERC20(tokenfrom).approve(address(this),amount);
        require(success,"Approval failed");

        // Transfer token to the contract
        success = ERC20(tokenfrom).transferFrom(msg.sender,address(this),amount);
        require(success,"Transfer failed");

        // Resolve if order hits
        resolveOrder(orderType.sell,token,amount,price,counter);

        return counter;

    }

    // Remove limit order
    function removeLimitOrder(uint256 _orderId) public {

        // Check if the order exists or not or has been resolved
        require(orderStatus[_orderId] == true,"The order does not exists");

        // Check if the caller is the limit seller
        require(order[_orderId]._caller == msg.sender,"Only the caller can remove the order");

        // Transfer token back to the caller
        address _tokenFrom = order[_orderId]._tokenfrom;
        uint256 _amount = order[_orderId]._amount;
        uint256 _type = order[_orderId]._orderType;
        bool success = ERC20(_tokenFrom).transfer(msg.sender,_amount);
        require(success,"Transfer failed");

        // Delete order data
        delete order[_orderId];
        // Update order status
        orderStatus[_orderId] = false;

        // Remove from active order list
        if(_type == orderType.sell){
            // Remove from active sellOrders
            for(uint i =0; i < activeSellOrders.length; i++){
                if(activeSellOrders[i] == _orderId){
                    // Replace with last element
                    activeSellOrders[i] = activeSellOrders[activeSellOrders.length-1];
                }
            }
            // Pop the last element
            activeSellOrders.pop();
        }
        else{
            // Remove from active buyOrders
            for(uint i =0; i < activeBuyOrders.length; i++){
                if(activeBuyOrders[i] == _orderId){
                    // Replace with last element
                    activeBuyOrders[i] = activeBuyOrders[activeSellOrders.length-1];
                }
            }
            // Pop the last element
            activeBuyOrders.pop();

        }
        
    }

    // Update limit order
    function updateLimitOrder(uint256 _orderId, uint256 amount) public {

        // Check if the order exists or not or has been resolved
        require(orderStatus[_orderId] == true,"The order does not exists");

        // Check if the caller is the limit seller
        require(order[_orderId]._caller == msg.sender,"Only the caller can remove the order");

        address _tokenFrom = order[_orderId]._tokenfrom;
        uint256 _existingAmount = order[_orderId]._amount;

        // Approve the token amount
        bool success = ERC20(_tokenFrom).approve(address(this),amount);
        require(success,"Approval failed");
        // Transfer the token to the contract
        success = ERC20(_tokenFrom).transferFrom(msg.sender,address(this),amount);
        require(success,"Transfer failed");

        // Update the order 
        order[_orderId]._amount += amount;
    }

    // Limit buy


    // Limit sell from eth
    // function limitSellFromEth(address _toToken,uint256 price) public{
    //     // Get the amount of tokens to limit sell
    //     uint256 amount = msg.value;

    //     // Increment counter
    //     counter++;
    //     // Store order
    //     order[counter] = Order(orderType.sell,msg.sender,_toToken,amount,price);

    //     // Push to active sell orders
    //     activeSellOrders.push(counter);

    // }


}
