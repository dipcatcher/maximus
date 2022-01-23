// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;
import "@openzeppelin/contracts@4.4.1/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts@4.4.1/access/Ownable.sol";
import "@openzeppelin/contracts@4.4.1/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts@4.4.1/token/ERC20/utils/SafeERC20.sol";

contract MyToken is ERC20, Ownable {
    constructor() ERC20("MyToken", "MTK") { 
         
    }
    address CONTRACT_ADDRESS =address(this);
    //address DAO_ADDRESS = 0x0bDcEC2E73B6b630fBC8137c36ba2d677aB94025;
    address HEX_ADDRESS = 0x2b591e99afE9f32eAA6214f7B7629768c40Eeb39;
    IERC20 hex_contract = IERC20(HEX_ADDRESS);
    function mint(uint256 amount) private {
        _mint(msg.sender, amount);
    }
    function getBalanceHEX() public view returns (uint256) {
        return hex_contract.balanceOf(msg.sender);
    }
    function getAllowanceHEX() public view returns (uint256) {
        return hex_contract.allowance(msg.sender, CONTRACT_ADDRESS);
    }
    function pledgeHEX(uint256 amount) public {
        address from = msg.sender;
        hex_contract.transferFrom(from, CONTRACT_ADDRESS, amount);
        uint256 mint_amount = amount * 10000000000;
        mint(mint_amount);
    }
    function _stakeHEX(uint256 amount) private  {
        //IERC20 hc = IERC20(HEX_ADDRESS);
        //hc.stakeStart(amount,1);
        StakeableToken hc = StakeableToken(HEX_ADDRESS);
        hc.stakeStart(amount,1);
    }
    function stakeHEX(uint256 amount) public {
        _stakeHEX(amount);
    }

    
    
    
}
