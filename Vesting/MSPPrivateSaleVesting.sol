// SPDX-License-Identifier: MIT
// Power by: Meta Super Pet

pragma solidity ^0.8.0;

import "./MSPVesting.sol";

// IMPORTANT: The monthly unvesting is unleaseed at the end of each month.

/**
 * @dev PrivateSaleMSPVesting will be claimed 6% at TGE, then blocked for 2 month, and release 5% each month.
 * Hence, the vestingDuration should be 18 months (18 * 5% = 90%, user get 9% on the 18th month.)
 * The Cliff is 1 (the first monthly claim will be enabled 60 days after the TGE)
 */
contract PrivateSaleMSPVesting is MSPVesting {

  // put the token address here
  // This should be included in the contract for transparency
  address public MSP_TOKEN_ADDRESS = 0x5270556791Ae9f924a892A46DDd0b0b449281365;

  // put the startAtTimeStamp here
  // 1651329000 : Saturday, April 30, 2022 2:30:00 PM UTC
  // To test all contracts, change this timestamp to time in the past.
  uint256 public startAtTimeStamp = 1651329000;

  // Each month equals 30 days: 30*24*60*60 .Note: change this value to 300 to test on testnet
  uint256 internal constant _SECONDS_PER_MONTH = 2592000;
  
  // @dev constructor creates the vesting contract
  // @param _token Address of MSP token
  // @param _owner Address of owner of this contract
  // @param _vestingStartAt the starting timestamp of vesting , in seconds.
  // @param _monthlyDuration the duration since monthlyStartAt until the vesting ends, in months.
  // @param _percentClaimAtTGE the percent of vested token that can be claimed after TGE. input 6 for 6%
  // @param _vestingCliff the cooldown period after _vestingStartAt, so that the monthly vesting will start, in seconds.
  // @param _percentUnleasePerMonth the percent of vested token which can be claimed per month;
  // @param _secondPerMonth the second per month. Each month equals 30 days
  constructor() MSPVesting(MSP_TOKEN_ADDRESS, msg.sender, startAtTimeStamp, 18, 6, (2 *_SECONDS_PER_MONTH), 5, _SECONDS_PER_MONTH) {}
}