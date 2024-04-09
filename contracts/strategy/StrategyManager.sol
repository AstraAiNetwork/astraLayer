// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";


import "../interfaces/IStrategy.sol";
import "../interfaces/IStrategyManager.sol";
import "../structs/StrategyStruct.sol";
import "../interfaces/IAccount.sol";


contract StrategyManager is IStrategyManager, ReentrancyGuard{

     Strategy[] public strategies;

     mapping(address => uint256[]) private ownerToStrategyIds;
     mapping(address => uint256[]) private contractToStrategyIds;
     mapping(address => mapping(uint256 => uint256)) private ownerStrategyIndex;
     mapping(address => mapping(uint256 => uint256)) private contractStrategyIndex;


    event StrategyAdded(uint256 indexed strategyId, address indexed owner, address strategyContract, address rewardToken, uint256 rewardAmount);
    event StrategyExecuted(uint256 indexed strategyId);
    event StrategyExecutionFailed(uint256 indexed strategyId);
    event StrategyRemoved(uint256 indexed strategyId);

    constructor( ) {
    }

    function addStrategy(
        address _strategyContract,
        bytes calldata _conditionData,
        bytes calldata _executeData,
        address _rewardToken,
        uint256 _rewardAmount
    ) external nonReentrant override {
        IERC20(_rewardToken).transferFrom(msg.sender, address(this), _rewardAmount);
        uint256 strategyId = strategies.length;
        strategies.push(Strategy({
            owner: msg.sender,
            strategyContract: _strategyContract,
            conditionData: _conditionData,
            executeData: _executeData,
            rewardToken: _rewardToken,
            rewardAmount: _rewardAmount,
            status: StrategyStatus.Created,
            createdAt: block.timestamp,
            executedAt: 0,
            executeUser : address(0)
        }));
        uint256 index = strategies.length - 1;
        ownerToStrategyIds[msg.sender].push(strategyId);
        contractToStrategyIds[_strategyContract].push(strategyId);
        ownerStrategyIndex[msg.sender][strategyId] = index;
        contractStrategyIndex[_strategyContract][strategyId] = index;

        emit StrategyAdded(strategies.length - 1, msg.sender, _strategyContract, _rewardToken, _rewardAmount);
    }
    function removeStrategy(uint256 strategyId) external nonReentrant {
        require(strategyId < strategies.length, "StrategyManager: strategy does not exist");
        Strategy memory strategy = strategies[strategyId];
        require(strategy.status == StrategyStatus.Created, "StrategyManager: strategy cannot be removed once executed");
        require(strategy.owner == msg.sender, "StrategyManager: not owner");

        uint256 lastIndex = strategies.length - 1;
        if (strategyId != lastIndex) {
            Strategy storage lastStrategy = strategies[lastIndex];
            strategies[strategyId] = lastStrategy; // Move the last strategy to the slot of the one to be removed

            // Update the indices in the owner and contract mappings
            uint256 lastStrategyId = lastIndex; 
            ownerToStrategyIds[lastStrategy.owner][ownerStrategyIndex[lastStrategy.owner][lastStrategyId]] = strategyId;
            contractToStrategyIds[lastStrategy.strategyContract][contractStrategyIndex[lastStrategy.strategyContract][lastStrategyId]] = strategyId;

            // Update the reverse mappings
            ownerStrategyIndex[lastStrategy.owner][strategyId] = ownerStrategyIndex[lastStrategy.owner][lastStrategyId];
            contractStrategyIndex[lastStrategy.strategyContract][strategyId] = contractStrategyIndex[lastStrategy.strategyContract][lastStrategyId];

            // Clean up old indices
            delete ownerStrategyIndex[lastStrategy.owner][lastStrategyId];
            delete contractStrategyIndex[lastStrategy.strategyContract][lastStrategyId];
        }

        strategies.pop(); // Remove the last element
        emit StrategyRemoved(strategyId);
}


   
    function checkAndExecute(uint256 _strategyId,address rewardReceipt) nonReentrant override external {
        _check(_strategyId);
        Strategy storage strategy = strategies[_strategyId]; 

        (address dest, uint256 value, bytes memory func) = abi.decode(strategy.executeData,(address , uint256 , bytes ));
        require(IAccount(strategy.owner).executeStrategy(dest,value,func),"execute failed");
         strategy.status = StrategyStatus.Executed;
         strategy.executedAt = block.timestamp;
         strategy.executeUser = msg.sender;
         IERC20(strategy.rewardToken).transfer(rewardReceipt, strategy.rewardAmount);  
         emit StrategyExecuted(_strategyId);
    }

    function check(uint256 _strategyId) external view override returns (bool) {
        _check(_strategyId);
        return true;
    }
    function _check(uint256 _strategyId) internal view{
        require(_strategyId < strategies.length, "Strategy does not exist.");
        Strategy memory strategy = strategies[_strategyId];
        IStrategy strategyContract = IStrategy(strategy.strategyContract);
        require(strategy.createdAt > 0, "Strategy does not exist.");
        require(strategy.status == StrategyStatus.Created, "Strategy executed.");
        require (strategyContract.checkCondition(strategy.conditionData),"condition not met");
    }

    function getStrategyCount() external view override returns (uint256) {
        return strategies.length;
    }

    function getStrategy(uint256 _strategyId) external view override returns (Strategy memory) {
        require(_strategyId < strategies.length, "Strategy does not exist.");
        return strategies[_strategyId];
    }
    function getStrategiesByUser(address owner) external view returns (Strategy[] memory) {
        uint256[] memory ids = ownerToStrategyIds[owner];
        Strategy[] memory ownerStrategies = new Strategy[](ids.length);
        for (uint256 i = 0; i < ids.length; i++) {
            ownerStrategies[i] = strategies[ids[i]];
        }
        return ownerStrategies;
    }

    function getStrategiesByContract(address strategyContract) external view returns (Strategy[] memory) {
        uint256[] memory ids = contractToStrategyIds[strategyContract];
        Strategy[] memory contractStrategies = new Strategy[](ids.length);
        for (uint256 i = 0; i < ids.length; i++) {
            contractStrategies[i] = strategies[ids[i]];
        }
        return contractStrategies;
    }

}
