// SPDX-License-Identifier: MIT
// Power by: Meta Super Pet

pragma solidity ^0.8.0;

import "./MSPVesting.sol";

// IMPORTANT: The monthly unvesting is unleaseed at the end of each month.

/**
 * @dev MSPAirdrop will be claimed 34% after TGE 1 week, release 33% next month, and 33% for the last month.
 * No cliff.
 */
contract MSPAirdrop is MSPVesting {

  // put the token address here
  // This should be included in the contract for transparency
  address public MSP_TOKEN_ADDRESS = 0x5270556791Ae9f924a892A46DDd0b0b449281365;

  // put the startAtTimeStamp here
  // 1651845600 : Friday, May 6, 2022 2:00:00 PM UTC
  // To test all contracts, change this timestamp to time in the past.
  uint256 public startAtTimeStamp = 1651845600;

  // Each month equals 30 days: 30*24*60*60 .Note: change this value to 300 to test on testnet
  uint256 internal constant _SECONDS_PER_MONTH = 2592000;

  // @dev constructor creates the vesting contract
  // @param _token Address of MSP token
  // @param _owner Address of owner of this contract
  // @param _vestingStartAt the starting timestamp of vesting , in seconds.
  // @param _monthlyDuration the duration since monthlyStartAt until the vesting ends, in months.
  // @param _percentClaimAtTGE the percent of vested token that can be claimed after TGE. input 7 for 7%
  // @param _vestingCliff the cooldown period after _vestingStartAt, so that the monthly vesting will start, in seconds.
  // @param _percentUnleasePerMonth the percent of vested token which can be claimed per month;
  // @param _secondPerMonth the second per month. Each month equals 30 days
  constructor() MSPVesting(MSP_TOKEN_ADDRESS, msg.sender, startAtTimeStamp, 2, 34, 0, 33, _SECONDS_PER_MONTH) {}
}