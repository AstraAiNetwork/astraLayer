// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.12;

  enum StrategyStatus { Created, Executed, Failed }

   struct Strategy {
        address owner;
        address strategyContract;
        bytes conditionData; 
        bytes executeData;    
        address rewardToken;  
        uint256 rewardAmount;   
        StrategyStatus status;
        uint256 createdAt;
        uint256 executedAt;
        address executeUser;
    }

 
