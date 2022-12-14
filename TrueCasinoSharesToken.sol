// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract TrueCasinoSharesToken is ERC20, Ownable {
    constructor(string memory _name, string memory _symbol)  ERC20(_name, _symbol) 
    {
    }
    function mint(address _addr, uint256 _amount) external onlyOwner {
         _mint(_addr, _amount);
    }
    function burn(address _addr, uint256 _amount) external onlyOwner {
         _burn(_addr, _amount);
    }
}