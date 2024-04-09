// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.12;


import "../interfaces/IStrategyManager.sol";
import "../interfaces/IStrategy.sol";
import "../interfaces/IPriceOracle.sol";
import "../structs/StrategyStruct.sol";



 enum Operate {
      GreaterThan,    
      EqualTo,        
      LessThan,      
      GreaterOrEqual,
      LessOrEqual   
  }

  struct ExcuteCondition {
      address erc20;
      Operate operate;
      uint256 price;
  }

  struct ExcuteTx {
      address target;
      uint256 value;
      bytes data;
    }

contract PriceTriggerStrategy is IStrategy {

    error OperateError( );
    error PriceError( );
    error AddressError( );

    IPriceOracle public priceOracle;

    constructor() {
    }

    function checkCondition(bytes calldata data) external view override returns (bool) {
        ExcuteCondition memory condition = abi.decode(data, (ExcuteCondition));
       return _checkCondition(condition);
    }

     function _checkCondition( ExcuteCondition memory condition) internal view  returns (bool) {
        if(condition.erc20 == address(0)){
            revert AddressError();
        }
        uint256 price = priceOracle.getPrice(condition.erc20);
        if(price == 0){
            revert PriceError();
        }
        if(condition.operate == Operate.GreaterThan){
             return  price > condition.price;
        } 
        if(condition.operate == Operate.EqualTo){
             return  price == condition.price;
        } 
        if(condition.operate == Operate.LessThan){
             return  price < condition.price;
        } 
        if(condition.operate == Operate.GreaterOrEqual){
             return  price >= condition.price;
        } 
        if(condition.operate == Operate.LessOrEqual){
             return  price <= condition.price;
        } 
        revert OperateError();  
    }

    function parseTxData(Strategy memory data) public view returns (address owner, address strategyContract ,ExcuteCondition memory conditionData
    , ExcuteTx memory executeData,address rewardToken,uint256 rewardAmount,StrategyStatus status,uint256 createdAt,uint256 executedAt,address executeUser) {
        require(data.strategyContract != address(this));
        owner = data.owner;
        strategyContract = data.strategyContract;
        conditionData = abi.decode(data.conditionData, ( ExcuteCondition));
        executeData = abi.decode(data.executeData, ( ExcuteTx));
        rewardToken = data.rewardToken;
        rewardAmount = data.rewardAmount;
        status =  data.status;
        createdAt = data.createdAt;
        executedAt = data.executedAt;
        executeUser = data.executeUser;
    }

   
}
