// SPDX-License-Identifier: MIT
// Power by: VeBank

pragma solidity ^0.8.0;

import "./TokenVesting.sol";

// IMPORTANT: The monthly unvesting is unleaseed at the end of each month.

/**
 * @dev PreSeedVBVesting will be claimed 5% at TGE, and release 3.9583% each month.
 * The vestingDuration is 24 months. Each month is 3.9583%.
 * The Cliff is 0 because the first time monthly claiming started 1 month after TGE
 */
contract PreSeedVBVesting is TokenVesting {
  
  // @dev constructor creates the vesting contract
  // @param _token Address of VB token
  // @param _owner Address of owner of this contract
  // @param _vestingStartAt the starting timestamp of vesting , in seconds.
  // @param _monthlyDuration the duration since monthlyStartAt until the vesting ends, in months.
  // @param _percentClaimAtTGE the percent of vested token that can be claimed after TGE. input 5 for 5%
  // @param _vestingCliff the cooldown period after _vestingStartAt, so that the monthly vesting will start, in seconds.
  // @param _percentUnleasePerMonth the percent of vested token which can be claimed per month;
  // @param _secondPerMonth the second per month. Each month equals 30 days
  constructor(
    address _TOKEN_ADDRESS,
    uint256 _startAtTimeStamp,
    uint256 _SECONDS_PER_MONTH
  ) TokenVesting(_TOKEN_ADDRESS, msg.sender, _startAtTimeStamp, 24, 5, (0 *_SECONDS_PER_MONTH),_SECONDS_PER_MONTH) {}
}