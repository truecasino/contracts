// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract TestUSDCToken is ERC20, Ownable {
    constructor()  ERC20("TestUSDCToken", "TUSDC") 
    {
    }
    function mint(address _addr, uint256 _amount) external onlyOwner {
         _mint(_addr, _amount);
    }
}