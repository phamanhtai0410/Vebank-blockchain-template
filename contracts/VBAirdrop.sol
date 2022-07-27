// SPDX-License-Identifier: MIT
// Power by: Meta Super Pet

pragma solidity ^0.8.0;

import "./TokenVesting.sol";

// IMPORTANT: The monthly unvesting is unleaseed at the end of each month.

/**
 * @dev VBAirdrop will be claimed 10% after TGE 1 week, release 15% each month
 * The vestingDuration is 6 months. Each month is 15%.
 * No cliff.
 */
contract VBAirdrop is TokenVesting {

  // @dev constructor creates the vesting contract
  // @param _token Address of VB token
  // @param _owner Address of owner of this contract
  // @param _vestingStartAt the starting timestamp of vesting , in seconds.
  // @param _monthlyDuration the duration since monthlyStartAt until the vesting ends, in months.
  // @param _percentClaimAtTGE the percent of vested token that can be claimed after TGE. input 7 for 7%
  // @param _vestingCliff the cooldown period after _vestingStartAt, so that the monthly vesting will start, in seconds.
  // @param _percentUnleasePerMonth the percent of vested token which can be claimed per month;
  // @param _secondPerMonth the second per month. Each month equals 30 days
  constructor(
    address _TOKEN_ADDRESS,
    uint256 _startAtTimeStamp,
    uint256 _SECONDS_PER_MONTH
  ) TokenVesting(_TOKEN_ADDRESS, msg.sender, _startAtTimeStamp, 6, 10, 0,_SECONDS_PER_MONTH) {}
}