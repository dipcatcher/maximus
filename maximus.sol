//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.2;
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
contract HedronToken {
  function approve(address spender, uint256 amount) external returns (bool) {}
  function transfer(address recipient, uint256 amount) external returns (bool) {}
  function mintNative(uint256 stakeIndex, uint40 stakeId) external returns (uint256) {}
  function claimNative(uint256 stakeIndex, uint40 stakeId) external returns (uint256) {}
  function currentDay() external view returns (uint256) {}
}

contract HEXToken {
  function currentDay() external view returns (uint256){}
  function stakeStart(uint256 newStakedHearts, uint256 newStakedDays) external {}
  function approve(address spender, uint256 amount) external returns (bool) {}
  function transfer(address recipient, uint256 amount) public returns (bool) {}
  function stakeEnd(uint256 stakeIndex, uint40 stakeIdParam) public {}
  function stakeCount(address stakerAddr) external view returns (uint256) {}
}
// Maximus is a contract for trustlessly pooling a single max length hex stake.
// Anyone may choose to mint 1 MAXI per HEX deposited into the Maximus Contract Address during the minting phase.
// Anyone may choose to pay for the gas to start and end the stake on behalf of the Maximus Contract.
// Anyone may choose to pay for the gas to mint Hedron the stake earns on behalf of the Maximus Contract.
// MAXI is a standard ERC20 token only minted upon HEX deposit and burnt open HEX redemption with no pre-mine or contract fee.
// MAXI holders may choose to burn MAXI to redeem HEX principal and yield (Including HEDRON) pro-rata from the Maximus Contract Address during the redemption phase.
//
// |--- Minting Phase---|---------- 5555 Day Stake Phase ------------...-----|------ Redemption Phase ---------->


contract Maximus is ERC20, ERC20Burnable, ReentrancyGuard {
    // all days are measured in terms of the HEX contract day number
    uint256 MINTING_PHASE_START;
    uint256 MINTING_PHASE_END;
    uint256 STAKE_START_DAY;
    uint256 STAKE_END_DAY;
    uint256 STAKE_LENGTH;
    uint256 HEX_REDEMPTION_RATE; // Number of HEX units redeemable per MAXI
    uint256 HEDRON_REDEMPTION_RATE; // Number of HEDRON units redeemable per MAXI
    bool HAS_STAKE_STARTED;
    bool HAS_STAKE_ENDED;
    bool HAS_HEDRON_MINTED;
    address END_STAKER; 
    
    constructor(uint256 mint_duration, uint256 stake_duration) ERC20("Maximus", "MAXI") ReentrancyGuard() {
        uint256 start_day=hex_token.currentDay();
        MINTING_PHASE_START = start_day;
        MINTING_PHASE_END = start_day+mint_duration;
        STAKE_LENGTH=stake_duration; 
        HAS_STAKE_STARTED=false;
        HAS_STAKE_ENDED = false;
        HAS_HEDRON_MINTED=false;
        HEX_REDEMPTION_RATE=100000000; // HEX and MAXI are 1:1 convertible up until the stake is initiated
        HEDRON_REDEMPTION_RATE=0; //no hedron is redeemable until minting has occurred
        
        
    }
    
    /**
    * @dev View number of decimal places the MAXI token is divisible to. Manually overwritten from default 18 to 8 to match that of HEX. 1 MAXI = 10^8 mini
    */
    
    function decimals() public view virtual override returns (uint8) {
        return 8;
	}
    address MAXI_ADDRESS =address(this);
    address constant HEX_ADDRESS = 0x2b591e99afE9f32eAA6214f7B7629768c40Eeb39; // "2b, 5 9 1e? that is the question..."
    address constant HEDRON_ADDRESS=0x3819f64f282bf135d62168C1e513280dAF905e06; // PULSECHAIN TESTNET HEDRON ADDRESS

    IERC20 hex_contract = IERC20(HEX_ADDRESS);
    IERC20 hedron_contract=IERC20(HEDRON_ADDRESS);
    HEXToken hex_token = HEXToken(HEX_ADDRESS);
    HedronToken hedron_token = HedronToken(HEDRON_ADDRESS);
    // public function
    /**
    * @dev Returns the HEX Day that the Minting Phase started.
    * @return HEX Day that the Minting Phase started.
    */
    function getMintingPhaseStartDay() external view returns (uint256) {return MINTING_PHASE_START;}
    /**
    * @dev Returns the HEX Day that the Minting Phase ends.
    * @return HEX Day that the Minting Phase ends.
    */
    function getMintingPhaseEndDay() external view returns (uint256) {return MINTING_PHASE_END;}
    /**
    * @dev Returns the HEX Day that the Maximus HEX Stake started.
    * @return HEX Day that the Maximus HEX Stake started.
    */
    function getStakeStartDay() external view returns (uint256) {return STAKE_START_DAY;}
    /**
    * @dev Returns the HEX Day that the Maximus HEX Stake ends.
    * @return HEX Day that the Maximus HEX Stake ends.
    */
    function getStakeEndDay() external view returns (uint256) {return STAKE_END_DAY;}
    /**
    * @dev Returns the rate at which MAXI may be redeemed for HEX. "Number of HEX hearts per 1 MAXI redeemed."
    * @return Rate at which MAXI may be redeemed for HEX. "Number of HEX hearts per 1 MAXI redeemed."
    */
    function getHEXRedemptionRate() external view returns (uint256) {return HEX_REDEMPTION_RATE;}
    /**
    * @dev Returns the rate at which MAXI may be redeemed for HEDRON.
    * @return Rate at which MAXI may be redeemed for HDRN.
    */
    function getHedronRedemptionRate() external view returns (uint256) {return HEDRON_REDEMPTION_RATE;}

    /**
    * @dev Returns the current HEX day."
    * @return Current HEX Day
    */
    function getHexDay() external view returns (uint256){
        uint256 day = hex_token.currentDay();
        return day;
    }
     /**
    * @dev Returns the current HEDRON day."
    * @return day Current HEDRON Day
    */
    function getHedronDay() external view returns (uint day) {return hedron_token.currentDay();}

     /**
    * @dev Returns the address of the person who ends stake. May be used by external gas pooling contracts. If stake has not been ended yet will return 0x000...000"
    * @return end_staker_address This person should be honored and celebrated as a hero.
    */
    function getEndStaker() external view returns (address end_staker_address) {return END_STAKER;}

    // MAXI Issuance and Redemption Functions
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
    function pledgeHEX(uint256 amount) nonReentrant external {
        require(hex_token.currentDay()<=MINTING_PHASE_END, "Minting Phase is Done");
        require(hex_contract.allowance(msg.sender, MAXI_ADDRESS)>=amount, "Please approve contract address as allowed spender in the hex contract.");
        address from = msg.sender;
        hex_contract.transferFrom(from, MAXI_ADDRESS, amount);
        mint(amount);
    }
     /**
     * @dev Ensures that it is currently a redemption period (before stake starts or after stake ends) and that the user has at least the number of maxi they entered. Then it calculates how much hex may be redeemed, burns the MAXI, and transfers them the hex.
     * @param amount_MAXI number of MAXI that the user is redeeming, measured in mini
     */
    function redeemHEX(uint256 amount_MAXI) nonReentrant external {
        require(HAS_STAKE_STARTED==false || HAS_STAKE_ENDED==true , "Redemption can only happen before stake starts or after stake ends.");
        uint256 yourMAXI = balanceOf(msg.sender);
        require(yourMAXI>=amount_MAXI, "You do not have that much MAXI.");
        uint256 raw_redeemable_amount = amount_MAXI*HEX_REDEMPTION_RATE;
        uint256 redeemable_amount = raw_redeemable_amount/100000000; //scaled back down to handle integer rounding
        burn(amount_MAXI);
        hex_token.transfer(msg.sender, redeemable_amount);
        if (HAS_HEDRON_MINTED==true) {
            uint256 raw_redeemable_hedron = amount_MAXI*HEDRON_REDEMPTION_RATE;
            uint256 redeemable_hedron = raw_redeemable_hedron/100000000; //scaled back down to handle integer rounding
            hedron_token.transfer(msg.sender, redeemable_hedron);
        }
    }
    //Staking Functions
    // Anyone may run these functions during the allowed time, so long as they pay the gas.
    // While nothing is forcing you to, gracious Maximus members will tip the sender some ETH for paying gas to end your stake.

    /**
     * @dev Ensures that the stake has not started yet and that the minting phase is over. Then it stakes all the hex in the contract and schedules the STAKE_END_DAY.
     * @notice This will trigger the start of the HEX stake. If you run this, you will pay the gas on behalf of the contract and you should not expect reimbursement.
     
     */
    function stakeHEX() nonReentrant external {
        require(HAS_STAKE_STARTED==false, "Stake has already been started.");
        uint256 current_day = hex_token.currentDay();
        require(current_day>MINTING_PHASE_END, "Minting Phase is still ongoing - see MINTING_PHASE_END day.");
        uint256 amount = hex_contract.balanceOf(address(this)); 
        _stakeHEX(amount);
        HAS_STAKE_STARTED=true;
        STAKE_START_DAY=current_day;
        STAKE_END_DAY=current_day+STAKE_LENGTH;
    }
    function _stakeHEX(uint256 amount) private  {
        hex_token.stakeStart(amount,STAKE_LENGTH);
        }
    
    function _endStakeHEX(uint256 stakeIndex,uint40 stakeIdParam ) private  {
        hex_token.stakeEnd(stakeIndex, stakeIdParam);
        }
    /**
     * @dev Ensures that the stake is fully complete and that it has not already been ended. Then it ends the hex stake and updates the redemption rate.
     * @notice This will trigger the ending of the HEX stake and calculate the new redemption rate. This may be very expensive. If you run this, you will pay the gas on behalf of the contract and you should not expect reimbursement.
     * @param stakeIndex index of stake found in stakeLists[contract_address] in hex contract.
     * @param stakeIdParam stake identifier found in stakeLists[contract_address] in hex contract.
     */
    function endStakeHEX(uint256 stakeIndex,uint40 stakeIdParam ) nonReentrant external {
        require(hex_token.currentDay()>STAKE_END_DAY, "Stake is not complete yet.");
        require(HAS_STAKE_STARTED==true && HAS_STAKE_ENDED==false, "Stake has already been started.");
        _endStakeHEX(stakeIndex, stakeIdParam);
        HAS_STAKE_ENDED=true;
        uint256 hex_balance = hex_contract.balanceOf(address(this));
        uint256 total_maxi_supply = IERC20(address(this)).totalSupply();
        HEX_REDEMPTION_RATE  = calculate_redemption_rate(hex_balance, total_maxi_supply);
        END_STAKER=msg.sender;
    }
    /**
     * @dev Calculates the pro-rata redemption rate of any coin per maxi. Scales value by 10^8 to handle integer rounding.
     * @param treasury_balance The balance of coins in the maximus contract address (either HEX or HEDRON)
     * @param maxi_supply total maxi supply
     * @return redemption_rate Number of units redeemable per 10^8 decimal units of MAXI. Is scaled back down by 10^8 on redemption transaction.
     */
    function calculate_redemption_rate(uint treasury_balance, uint maxi_supply) private view returns (uint redemption_rate) {
        uint256 scalar = 10**8;
        uint256 scaled = (treasury_balance * scalar) / maxi_supply; // scale value to calculate redemption amount per maxi and then divide by same scalar after multiplication
        return scaled;
    }
    
    /**
     * @dev Public function which calls the private function which is used for minting available HDRN accumulated by the contract stake. 
     * @notice This will trigger the minting of the mintable Hedron earned by the stake. If you run this, you will pay the gas on behalf of the contract and you should not expect reimbursement. If check to make sure this has not been run yet already or the transaction will fail.
     * @param stakeIndex index of stake found in stakeLists[contract_address] in hex contract.
     * @param stakeId stake identifier found in stakeLists[contract_address] in hex contract.
     */
  function mintHedron(uint256 stakeIndex,uint40 stakeId ) external  {
      _mintHedron(stakeIndex, stakeId);
        }
   /**
     * @dev Private function used for minting available HDRN accumulated by the contract stake and updating the HDRON redemption rate.
     * @param stakeIndex index of stake found in stakeLists[contract_address] in hex contract.
     * @param stakeId stake identifier found in stakeLists[contract_address] in hex contract.
     */
  function _mintHedron(uint256 stakeIndex,uint40 stakeId ) private  {
        hedron_token.mintNative(stakeIndex, stakeId);
        uint256 total_hedron= hedron_contract.balanceOf(address(this));
        uint256 total_maxi = IERC20(address(this)).totalSupply();
        
        HEDRON_REDEMPTION_RATE = calculate_redemption_rate(total_hedron, total_maxi);
        HAS_HEDRON_MINTED = true;
        }

}
