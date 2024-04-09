// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.12;

import "../structs/StrategyStruct.sol";

interface IStrategyManager {

    function addStrategy(address _strategyContract,
        bytes calldata _conditionData,
        bytes calldata _executeData,
        address _rewardToken,
        uint256 _rewardAmount) external ;

   function check(uint256 _strategyId) external view returns (bool);

    function checkAndExecute(uint256 _strategyId,address rewardReceipt) external;

    function getStrategyCount() external view returns (uint256);

    function getStrategy(uint256 _strategyId) external view returns (Strategy memory) ;
}