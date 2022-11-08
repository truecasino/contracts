// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface ITrueCasino {
    function buyChips(uint256 _amount) external;
    function sellChips(address _addr) external;
    function getUserBalance(address _addr) external view returns (uint256);
    function getCurrentLiquidity() external view returns (uint256);
    function makePayout(address _addr, uint256 _amount) external;
    function makeDeposit(address _addr, uint256 _amount) external;
    
    }