// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.12;

interface IPriceOracle {
    function getPrice(address ) external view returns (uint256);
}