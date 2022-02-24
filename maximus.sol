// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";


/// @title HEX Contract Proxy
/// @author Tanto Nomini
/// @notice You can use this contract for only the most basic simulation
/// @dev see HEX_CONTRACT_ADDRESS
contract HEXToken {
  function currentDay() external view returns (uint256){}
  function stakeStart(uint256 newStakedHearts, uint256 newStakedDays) external {}
  function approve(address spender, uint256 amount) external returns (bool) {}
  function transfer(address recipient, uint256 amount) public returns (bool) {}
  function stakeEnd(uint256 stakeIndex, uint40 stakeIdParam) public {}
  function stakeCount(address stakerAddr) external view returns (uint256) {}
  
}
contract MyToken is ERC20, ERC20Burnable, Ownable {
    // all days are measured in terms of the HEX contract day number
    uint256 MINTING_PHASE_START;
    uint256 MINTING_PHASE_END;
    bool HAS_STAKE_STARTED;
    bool HAS_STAKE_ENDED;
    uint256 STAKE_START_DAY;
    uint256 STAKE_END_DAY;
    uint256 REDEMPTION_RATE; 
    uint256 STAKE_LENGTH;
    uint256 STAKE_ID;
    
    constructor(uint256 start_day, uint256 duration) ERC20("MyToken", "MTK") {
        
        MINTING_PHASE_START = start_day;
        MINTING_PHASE_END = start_day+duration;
        HAS_STAKE_STARTED=false;
        HAS_STAKE_ENDED = false;
        REDEMPTION_RATE=1;
        STAKE_LENGTH=1; //5555;
    }
    function decimals() public view override returns (uint8) {
        // set MAXI to have 8 decimals to match HEX.
        return 8;
	}
    function get_amount_redeem_hex(uint amt) public view returns (uint256){
        uint256 RR = REDEMPTION_RATE;
        uint256 raw_amt = amt*RR;
        uint256 num_hex = percent(raw_amt, 10000, 4);
        return num_hex;
    }
    function get_redemption_rate() private view returns (uint256){
        uint256 hex_balance = hex_contract.balanceOf(address(this));
        uint256 total_maxi = IERC20(address(this)).totalSupply();
        uint256 RR = percent(hex_balance,total_maxi,8);
        return RR;
    }
    function percent(uint numerator, uint denominator, uint precision) public view returns(uint quotient) {

         // caution, check safe-to-multiply here
        uint _numerator  = numerator * 10 ** (precision+1);
        // with rounding of last digit
        uint _quotient =  ((_numerator / denominator) + 5) / 10;
        return ( _quotient);
  }
    address CONTRACT_ADDRESS =address(this);
    address HEX_ADDRESS = 0x2b591e99afE9f32eAA6214f7B7629768c40Eeb39; // "2b, 5 9 1e? that is the question..."
    
    IERC20 hex_contract = IERC20(HEX_ADDRESS);
    HEXToken token = HEXToken(HEX_ADDRESS);
    
    // getter functions
    function getMintingPhaseStartDay() public view returns (uint256) {return MINTING_PHASE_START;}
    function getMintingPhaseEndDay() public view returns (uint256) {return MINTING_PHASE_END;}

    function getStakeStartDay() public view returns (uint256) {return STAKE_START_DAY;}
    function getStakeEndDay() public view returns (uint256) {return STAKE_END_DAY;}
    
    function hasStakeStarted() public view returns (bool) {return HAS_STAKE_STARTED;}
    function getRedemptionRate() public view returns (uint256) {return REDEMPTION_RATE;}
    function get_hex_day() public view returns (uint256){
        uint256 day = token.currentDay();
        return day;
    }
    function getBalanceHEX() public view returns (uint256) {return hex_contract.balanceOf(msg.sender);}
    function getAllowanceHEX() public view returns (uint256) {return hex_contract.allowance(msg.sender, CONTRACT_ADDRESS);}
    function getNumStake() public view returns(uint256) {
            return token.stakeCount(address(this));
        }

    // MAXI issuance
    function mint(uint256 amount) private {
        
        _mint(msg.sender, amount);
    }
    function pledgeHEX(uint256 amount) public {
        require(HEXToken(HEX_ADDRESS).currentDay()<=MINTING_PHASE_END, "Minting Phase is Done");
        require(hex_contract.allowance(msg.sender, CONTRACT_ADDRESS)>=amount, "Please approve contract address as allowed spender in the hex contract.");
        address from = msg.sender;
        hex_contract.transferFrom(from, CONTRACT_ADDRESS, amount);
        mint(amount);
    }
    function redeemHEX(uint256 amount_MAXI) public {
        if (HAS_STAKE_STARTED==false || HAS_STAKE_ENDED==true) {
            uint256 yourMAXI = balanceOf(msg.sender);
            require(yourMAXI>=amount_MAXI, "You do not have that much MAXI.");
            uint256 redeemable_amount = amount_MAXI*REDEMPTION_RATE;
            burn(amount_MAXI);
            token.transfer(msg.sender, redeemable_amount);
        }
    }
    //STAKING
    // Anyone may run these functions during the allowed time, so long as they pay the gas.
    // While nothing is forcing you to, a gracious Maximus member will tip the sender some ETH for paying gas to end your stake.
    
    function stakeHEX() public {
        require(HAS_STAKE_STARTED==false, "Stake has already been started.");
        uint256 current_day = HEXToken(HEX_ADDRESS).currentDay();
        require(current_day>MINTING_PHASE_END, "Minting Phase is still ongoing - see MINTING_PHASE_END day.");
        uint256 amount = hex_contract.balanceOf(address(this)); //contract stakes all hex in the contract. even hex acccidentally sent to the contract without minting.
        _stakeHEX(amount);
        HAS_STAKE_STARTED=true;
        STAKE_START_DAY=current_day;
        STAKE_END_DAY=current_day+STAKE_LENGTH;
    }
    function _stakeHEX(uint256 amount) private  {
        token.stakeStart(amount,STAKE_LENGTH);
        }
    
    
    function _endStakeHEX(uint256 stakeIndex,uint40 stakeIdParam ) private  {
        token.stakeEnd(stakeIndex, stakeIdParam);
        }

    function endStakeHEX(uint256 stakeIndex,uint40 stakeIdParam ) public {
        // get stakeIndex and stakeIdParam from stakeLists[contract_address] in hex contract
        require(HEXToken(HEX_ADDRESS).currentDay()>STAKE_END_DAY, "Stake is not complete yet.");
        require(HAS_STAKE_STARTED==true && HAS_STAKE_ENDED==false, "Stake has already been started.");
        _endStakeHEX(stakeIndex, stakeIdParam);
        HAS_STAKE_ENDED=true;
        uint256 hex_balance = hex_contract.balanceOf(address(this));
        uint256 total_maxi = IERC20(address(this)).totalSupply();
        REDEMPTION_RATE = get_redemption_rate();
        
    }
    

    
}
