// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract testpercent {

function percent(uint numerator, uint denominator, uint precision) public view returns(uint quotient) {
        uint _numerator  = numerator * 10 ** (precision+1);
        //rounding of last digit
        uint _quotient =  ((_numerator / denominator) + 5) / 10;
        return ( _quotient);
  }

function redeem(uint value) public view returns(uint quotient) {
    uint256 v = value* percent(12380000000000,11254600000000,8)/100000000;
    return v;

}


}
