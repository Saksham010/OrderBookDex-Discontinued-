pragma solidity 0.8.14;

contract DexBook{
    // Type of order
    enum orderType{
        buy,
        sell
    }

    struct Order{
        orderType _orderType;
        address _caller;
        address _token;
        uint256 _amount;
        uint256 _price;
    }

    // Seller -> token -> amount
    // mapping (address => mapping(address=>uint256)) sellOrder;
    // mapping(address => mapping(address => uint256)) buyOrder; //Buyer -> token -> amount

    // Order id => 
    mapping(uint256=>Order) public order;
    // Active sell orders
    uint256[] activeSellOrders;
    // Active buy orders
    uint256[] activeBuyOrders;
    uint256 counter;

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


    // Put a limit sell order
    function limitSell(address token,uint256 amount, uint256 price) public {

        // Increment counter
        counter++;
        // Store order
        order[counter] = Order(orderType.sell,msg.sender,token,amount,price);

        // Push to active sell orders
        activeSellOrders.push(counter);

        // Approve token transfer 


        // Transfer token to the contract


        // Resolve if order hits
        resolveOrder(orderType.sell,token,amount,price,counter);

    }


}
