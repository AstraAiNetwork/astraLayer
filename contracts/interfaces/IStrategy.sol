// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.12;

interface IStrategy {
    function checkCondition(bytes calldata data) external view returns (bool);
}