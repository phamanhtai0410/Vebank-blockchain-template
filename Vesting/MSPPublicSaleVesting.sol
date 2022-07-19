// SPDX-License-Identifier: MIT
// Power by: Meta Super Pet

pragma solidity ^0.8.0;

import "./MSPVesting.sol";

/**
 * @dev PublicSaleMSPVesting (IDO) will be claimed 20% at TGE, and release 16% each month.
 * The vestingDuration is 5 months. Each month is 16%.
 * The Cliff is 0 because the first time monthly claiming started 1 month after TGE
 *
 */
contract PublicSaleMSPVesting is MSPVesting {
    // put the token address here
  // This should be included in the contract for transparency
  address public MSP_TOKEN_ADDRESS = 0x5270556791Ae9f924a892A46DDd0b0b449281365;

  // put the startAtTimeStamp here
  // 1651242600 : Friday, April 29, 2022 2:30:00 PM UTC
  // To test all contracts, change this timestamp to time in the past.
  uint256 public startAtTimeStamp = 1651242600;

  // Each month 30 days: 30*24*60*60 .Note: change this value to 300 to test on testnet
  uint256 internal constant _SECONDS_PER_MONTH = 2592000;

  // @dev constructor creates the vesting contract
  // @param _token Address of MSP token
  // @param _owner Address of owner of this contract
  // @param _vestingStartAt the starting timestamp of vesting , in seconds.
  // @param _monthlyDuration the duration since monthlyStartAt until the vesting ends, in months.
  // @param _percentClaimAtTGE the percent of vested token that can be claimed after TGE. input 20 for 20%
  // @param _vestingCliff the cooldown period after _vestingStartAt, so that the monthly vesting will start, in seconds.
  // @param _percentUnleasePerMonth the percent of vested token which can be claimed per month;
  // @param _secondPerMonth the second per month. Each month equals 30 days
  constructor() MSPVesting(MSP_TOKEN_ADDRESS, msg.sender, startAtTimeStamp, 5, 20, 0, 16, _SECONDS_PER_MONTH) {}
}