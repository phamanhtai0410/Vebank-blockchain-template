// SPDX-License-Identifier: MIT
// Power by: VeBank

pragma solidity ^0.8.0;

import "./TokenVesting.sol";

// IMPORTANT: The monthly unvesting is unleaseed at the end of each month.

/**
 * @dev PreSeedVBVesting will be locked at TGE
 * Hence, the vestingDuration should be 24 months (24 * 4.167% = 100%)
 * The Cliff is 6 months (the first monthly claim will be enabled 210 days after the TGE)
 */
contract PreSeedVBVesting is TokenVesting {
  
  // @dev constructor creates the vesting contract
  // @param _token Address of VB token
  // @param _owner Address of owner of this contract
  // @param _vestingStartAt the starting timestamp of vesting , in seconds.
  // @param _monthlyDuration the duration since monthlyStartAt until the vesting ends, in months.
  // @param _percentClaimAtTGE the percent of vested token that can be claimed after TGE. input 0 for 0%
  // @param _vestingCliff the cooldown period after _vestingStartAt, so that the monthly vesting will start, in seconds.
  // @param _percentUnleasePerMonth the percent of vested token which can be claimed per month;
  // @param _secondPerMonth the second per month. Each month equals 30 days
  constructor(
    address _TOKEN_ADDRESS,
    uint256 _startAtTimeStamp,
    uint256 _SECONDS_PER_MONTH
  ) TokenVesting(_TOKEN_ADDRESS, msg.sender, _startAtTimeStamp, 6, 20, (3 *_SECONDS_PER_MONTH),_SECONDS_PER_MONTH) {}
}