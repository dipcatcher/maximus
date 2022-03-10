
pragma solidity ^0.8.2;
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";


/// @title HEX Contract Proxy
/// @author Tanto Nomini
/// @dev HEX Contract Proxy

contract HedronToken {
  
  function approve(address spender, uint256 amount) external returns (bool) {}
  function transfer(address recipient, uint256 amount) external returns (bool) {}
  
  function mintNative(uint256 stakeIndex, uint40 stakeId) external returns (uint256) {}
 
}

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
    uint256 HEDRON_REDEMPTION_RATE;
    bool HAS_HEDRON_MINTED;
    uint256 STAKE_LENGTH;
    uint256 STAKE_ID;
    
    constructor(uint256 start_day, uint256 duration) ERC20("Maximus", "MAXI") {
        
        MINTING_PHASE_START = start_day;
        MINTING_PHASE_END = start_day+duration;
        HAS_STAKE_STARTED=false;
        HAS_STAKE_ENDED = false;
        HAS_HEDRON_MINTED=false;
        REDEMPTION_RATE=100000000; // HEX and MAXI are 1:1 convertible up until the stake is initiated
        HEDRON_REDEMPTION_RATE=100000000;
        STAKE_LENGTH=5; //change to 5555 on prod;
    }
    
    /**
    * @dev View number of decimal places the MAXI token is divisible to. Manually set to 8 to match that of HEX. 1 MAXI = 10^8 mini
    
    */
    function decimals() public view override returns (uint8) {
        return 8;
	}
    address CONTRACT_ADDRESS =address(this);
    address HEX_ADDRESS = 0x2b591e99afE9f32eAA6214f7B7629768c40Eeb39; // "2b, 5 9 1e? that is the question..."
    /*
    HDRN Token Contract Addresses:

    Pulse Testnet V2
    0xDC11f7E700A4c898AE5CAddB1082cFfa76512aDD

    Ethereum
    0x3819f64f282bf135d62168C1e513280dAF905e06
    */
    address HEDRON_ADDRESS=0xDC11f7E700A4c898AE5CAddB1082cFfa76512aDD;
    IERC20 hex_contract = IERC20(HEX_ADDRESS);
    HEXToken token = HEXToken(HEX_ADDRESS);
    HedronToken hedron_token = HedronToken(HEDRON_ADDRESS);
    // public function
    /**
    * @dev Returns the HEX Day that the Minting Phase started.
    * @return HEX Day that the Minting Phase started.
    */
    function getMintingPhaseStartDay() public view returns (uint256) {return MINTING_PHASE_START;}
    /**
    * @dev Returns the HEX Day that the Minting Phase ends.
    * @return HEX Day that the Minting Phase ends.
    */
    function getMintingPhaseEndDay() public view returns (uint256) {return MINTING_PHASE_END;}
    /**
    * @dev Returns the HEX Day that the Maximus HEX Stake started.
    * @return HEX Day that the Maximus HEX Stake started.
    */
    function getStakeStartDay() public view returns (uint256) {return STAKE_START_DAY;}
    /**
    * @dev Returns the HEX Day that the Maximus HEX Stake ends.
    * @return HEX Day that the Maximus HEX Stake ends.
    */
    function getStakeEndDay() public view returns (uint256) {return STAKE_END_DAY;}
    /**
    * @dev Returns the rate at which MAXI may be redeemed for HEX. "Number of HEX hearts per 1 MAXI redeemed."
    * @return Rate at which MAXI may be redeemed for HEX. "Number of HEX hearts per 1 MAXI redeemed."
    */
    function getRedemptionRate() public view returns (uint256) {return REDEMPTION_RATE;}

    /**
    * @dev Returns the current HEX day."
    * @return Current HEX Day
    */
    function getHexDay() public view returns (uint256){
        uint256 day = token.currentDay();
        return day;
    }


    // MAXI Minting Functions

    /**
     * @dev Mints MAXI.
     * @param amount of MAXI to mint, measured in minis
     */
    function mint(uint256 amount) private {
        _mint(msg.sender, amount);
    }
     /**
     * @dev Ensures that MAXI Minting Phase is ongoing and that the user has allowed the Maximus Contract address to spend the amount of HEX the user intends to pledge to Maximus DAO. Then sends the designated HEX from the user to the Maximus Contract address and mints 1 MAXI per HEX pledged.

     * @param amount of HEX user chose to pledge, measured in hearts
     */
    function pledgeHEX(uint256 amount) public {
        require(HEXToken(HEX_ADDRESS).currentDay()<=MINTING_PHASE_END, "Minting Phase is Done");
        require(hex_contract.allowance(msg.sender, CONTRACT_ADDRESS)>=amount, "Please approve contract address as allowed spender in the hex contract.");
        address from = msg.sender;
        hex_contract.transferFrom(from, CONTRACT_ADDRESS, amount);
        mint(amount);
    }

     /**
     * @dev Ensures that it is currently a redemption period and that the user has at least the number of maxi they entered. Then it calculates how much hex may be redeemed, burns the MAXI, and transfers them the hex..

     * @param amount_MAXI number of MAXI that the user is redeeming, measured in mini
     */
    function redeemHEX(uint256 amount_MAXI) public {
        require(HAS_STAKE_STARTED==false || HAS_STAKE_ENDED==true , "Redemption can only happen before stake starts or after stake ends.");
        uint256 yourMAXI = balanceOf(msg.sender);
        require(yourMAXI>=amount_MAXI, "You do not have that much MAXI.");
        uint256 raw_redeemable_amount = amount_MAXI*REDEMPTION_RATE;
        uint256 redeemable_amount = raw_redeemable_amount/100000000;
        uint256 raw_redeemable_hedron = amount_MAXI*HEDRON_REDEMPTION_RATE;
        uint256 redeemable_hedron = raw_redeemable_hedron/100000000;


        burn(amount_MAXI);
        token.transfer(msg.sender, redeemable_amount);
        if (HAS_HEDRON_MINTED==true) {
            hedron_token.transfer(msg.sender, redeemable_hedron);

        }
        
    }
    //Staking Functions
    // Anyone may run these functions during the allowed time, so long as they pay the gas.
    // While nothing is forcing you to, gracious Maximus members will tip the sender some ETH for paying gas to end your stake.

    /**
     * @dev Ensures that the stake has not started yet and that the minting phase is over. Then it stakes all the hex in the contract and schedules the STAKE_END_DAY.
     */
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
    /**
     * @dev Ensures that the stake is fully complete and that it has not already been ended. Then it ends the hex stake and updates the redemption rate.
     * @param stakeIndex index of stake found in stakeLists[contract_address] in hex contract.
     * @param stakeIdParam stake identifier found in stakeLists[contract_address] in hex contract.
     */
    function endStakeHEX(uint256 stakeIndex,uint40 stakeIdParam ) public {
        require(HEXToken(HEX_ADDRESS).currentDay()>STAKE_END_DAY, "Stake is not complete yet.");
        require(HAS_STAKE_STARTED==true && HAS_STAKE_ENDED==false, "Stake has already been started.");
        _endStakeHEX(stakeIndex, stakeIdParam);
        HAS_STAKE_ENDED=true;
        REDEMPTION_RATE = get_redemption_rate();
    }
    /**
     * @dev Calculates the redemption rate, the number of HEX in the contract after stake end divided by the total number of MAXI.
     * @return Redemption Rate "HEX redeemable per MAXI burnt"
     */
    function get_redemption_rate() private view returns (uint256){
        uint256 hex_balance = hex_contract.balanceOf(address(this));
        uint256 total_maxi = IERC20(address(this)).totalSupply();
        uint256 RR = percent(hex_balance,total_maxi,8);
        return RR;
    }
    /**
     * @dev Used to calculate a ratio considering decimal rounding.
     * @param numerator HEX balance of contract address after stake ends
     * @param denominator Total MAXI supply
     * @param precision number of decimals to cut off at.
     * @return quotient 
     */
    function percent(uint numerator, uint denominator, uint precision) public view returns(uint quotient) {
        // helper for calculating percent
         // caution, check safe-to-multiply here
        uint _numerator  = numerator * 10 ** (precision+1);
        // with rounding of last digit
        uint _quotient =  ((_numerator / denominator) + 5) / 10;
        return ( _quotient);

    
  }

  function mintHedron(uint256 stakeIndex,uint40 stakeId ) public  {
      require(HEXToken(HEX_ADDRESS).currentDay()>STAKE_END_DAY-2, "Hedron may only be minted in the last two days of the stake.");
      require(HAS_STAKE_ENDED ==false, "Stake must be ongoing to mint hedron.");
      _mintHedron(stakeIndex, stakeId);
      HAS_HEDRON_MINTED=true;
        
        }
  function _mintHedron(uint256 stakeIndex,uint40 stakeId ) private  {
      
        uint256 num_hedron = hedron_token.mintNative(stakeIndex, stakeId);
        uint256 total_maxi = IERC20(address(this)).totalSupply();
        HEDRON_REDEMPTION_RATE = percent(num_hedron, total_maxi, 8);
        }
}
