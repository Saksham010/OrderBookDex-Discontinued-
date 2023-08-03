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

    struct tokenPair{
        address tokenA;
        address tokenB;
    }

    struct Order{
        orderType _orderType;
        address _caller;
        address _tokenfrom;
        address _tokento;
        uint256 _amount;
        uint256 _price;
    }

    // List of token pair
    tokenPair [] tokenPairList;
    mapping(address=>mapping(address=>bool)) isActive; 

    // Order id => 
    mapping(uint256=>Order) public order;
    mapping(uint256 => bool) public orderStatus;

    // Order id
    uint256 orderId;
    // Active sell orders
    uint256[] activeSellOrders;
    // Active buy orders
    uint256[] activeBuyOrders;

    // Buy/Sell,orderId,tokenFrom,tokenTo,amount,timestamp
    event limitOrder(uint256,uint256,address,address,uint256,uint256);
    event incrementLimit(uint256,uint256,address,address,uint256,uint256);
    event decrementLimit(uint256,uint256,address,address,uint256,uint256);
    event removeLimit(uint256,uint256,address,address,uint256,uint256);

    // Sort tokens
    function sort(address token1, address token2) internal returns(address,address) {
        address tokenA = token1 < token2?token1:token2;
        address tokenB = token1 < token2? token2:token;        
        return (tokenA,tokenB);
    }

    // Verify two orders are for same token pair
    function verifypair(address btokenfrom,address btokento, address stokenfrom, address stokento) internal returns(bool){
        // Sort tokens
        (address _btoken0, address _btoken1) = sort(btokenfrom,btokento);
        (address _stoken0, address _stoken1) = sort(stokenfrom,stokento);

        return (_btoken0 == _stoken0 && _btoken1 == _stoken1)?true:false;
    }

    // Resolve if the order hits
    function resolveOrder(orderType _orderType, address tokenfrom, address tokento, uint256 amount, uint256 price,uint256 sellId)internal returns(bool){

        if(_orderType == orderType.sell){

            
            for(uint i; i < activeBuyOrders.length;i++){

                // Current order id
                uint256 buyId = activeBuyOrders[i];
                address buyerTokenFrom = order[buyId]._tokenfrom;
                address buyerTokenTo = order[buyId]._tokento;
                address buyerPrice = order[buyId]._price;
                uint256 buyerAmount = order[buyId]._amount;

                // Check if the exchange token matches 
                bool match = verifypair(buyerTokenFrom,buyerTokenTo,tokenfrom,tokento);
                
                if(match && buyerPrice == price){
                    
                    if(buyerAmount >= amount){
                        // Update buyer amount
                        order[buyId]._amount = buyerAmount - amount;
                        // Update seller amount
                        order[sellId]._amount = 0;
                    }
                    else{
                        // Update seller amount
                        order[sellId]._amount = amount -buyerAmount;
                        // Update buyer amount
                        order[buyId]._amount -= 0
                    }
                    // Resolve order
            
                }
            }
        }
        
    }


    function limitOrder(address tokenfrom,address tokento,uint256 amount, uint256 price) public returns(uint256) {
        //Initialize amount to sell
        uint256 _amountToSell = amount;

        // Increment order id
        orderId++;

        // Sort the tokens
        (address _tokenA, address _tokenB) = sort(tokenfrom,tokento);

        // Check if the pair is already initialized
        if(!isActive[_tokenA][_tokenB]){
            // If not initialize a new pair
            tokenPairList.append(tokenPair(_tokenA,_tokenB));
            isActive[_tokenA][_tokenB] = true;
        }
        else{
            // PEPE/USD     //Selling based on TokenA
            if(_tokenA == tokenfrom){
                // Save order
                order[orderId] = Order(orderType.sell,msg.sender,tokenfrom,tokento,amount,price)
                // Add to active sell orders
                activeSellOrders.push(orderId);
            }else if(_tokenA == tokento){
                // Buying based on tokenA
                // Save order
                order[orderId] = Order(orderType.buy,msg.sender,tokenfrom,tokento,amount,price);
                activeBuyOrders.push(orderId);
                // Amount of tokenB to sell
                _amountToSell = amount * price;
            }
        }
        // Set order status
        orderStatus[orderId] = true;

        // Approve token transfer 
        bool success = ERC20(tokenfrom).approve(address(this),amount);
        require(success,"Approval failed");

        // Transfer token to the contract
        success = ERC20(tokenfrom).transferFrom(msg.sender,address(this),amount);
        require(success,"Transfer failed");

        // Emit event
        emit limitOrder(_type,orderId,tokenfrom,tokento,amount,block.timestamp);    
    }

    // Increase order amount
    function incrementLimitOrder(uint256 _orderId,uint256 amount) public{

        // Check if the order exists or not or has been resolved
        require(orderStatus[_orderId] == true,"The order does not exists");

        // Check if the caller placed the order
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

        // Emit event
        emit incrementLimit(order[_orderId]._orderType,_orderId,_tokenFrom,order[_orderId]._tokento,order[_orderId]._amount,block.timestamp);

    }

    // Decrease order amount
    function decrementLimitOrder(uint256 _orderId,uint256 amount) public{

        // Check if the order exists or not or has been resolved
        require(orderStatus[_orderId] == true,"The order does not exists");

        // Check if the caller placed the order
        require(order[_orderId]._caller == msg.sender,"Only the caller can remove the order");

        address _tokenFrom = order[_orderId]._tokenfrom;
        uint256 _existingAmount = order[_orderId]._amount;

        // Check if the amount is more than the existing amount
        require(_amount >= _existingAmount,"Cannot decrease more the placed order amount");

        // Transfer the token from the contract to user
        bool success = ERC20(_tokenFrom).transfer(msg.sender,amount);
        require(success,"Transfer failed");

        // Update the order 
        order[_orderId]._amount -= amount;

        // Emit event
        emit decrementLimit(order[_orderId]._orderType,_orderId,_tokenFrom,order[_orderId]._tokento,order[_orderId]._amount,block.timestamp);

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

        //Emit event
        emit removeLimit(_type,_orderId,_tokenFrom,order[_orderId]._tokento,_amount,block.timestamp);

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
    
}