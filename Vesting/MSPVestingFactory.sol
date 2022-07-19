// SPDX-License-Identifier: MIT
// Power by: Meta Super Pet

pragma solidity ^0.8.0;

import "./MSPVesting.sol";

// IMPORTANT: The monthly unvesting is unleaseed at the end of each month, so that the Cliff is substracted by 1 month.


/**
 * @dev CoreTeamMSPVesting will be blocked for 12 months,
 * then releaseed 4% each month.
 * Hence, if _vestingStartAt is set to _TGETimeStamp, then the Cliff is just 11 months.
 * and the vestingDuration should be 25 months (25 * 4% = 100%)
 *
 */
contract CoreTeamMSPVesting is MSPVesting {
  constructor(
    address _token,
    address _owner,
    uint256 _TGETimeStamp,
    uint256 _SECONDS_PER_MONTH
  ) MSPVesting(_token, _owner, _TGETimeStamp, 25, 0, (11 * _SECONDS_PER_MONTH), 4, _SECONDS_PER_MONTH) {}
}

/**
 * @dev LiquidityMSPVesting will be unblocked 30% at TGE,
 * cliff for 0 months after TGE,
 * then releaseed 5% each month (14 months in total)
 * But the 30% will be transfer directly to the dex, without putting into this contract.
 * Hence, the vestingDuration should be 14 months.
 * The montly claim will be 7% (7% *14 = 98%) the total amount put into this contract (9% for last month)
 */
contract LiquidityMSPVesting is MSPVesting {
  constructor(
    address _token,
    address _owner,
    uint256 _TGETimeStamp,
    uint256 _SECONDS_PER_MONTH
  ) MSPVesting(_token, _owner, _TGETimeStamp, 14, 0, 0, 7, _SECONDS_PER_MONTH) {}
}

/**
 * @dev ReserveMSPVesting will be blocked for 9 months,
 * then releaseed 6% each month.
 * Hence, if _vestingStartAt is set to _TGETimeStamp, then the Cliff is just 8 months.
 * and the vestingDuration should be 16 months (16 * 6% = 100%), at 16th month release last 10%.
 *
 */
contract ReserveMSPVesting is MSPVesting {
  constructor(
    address _token,
    address _owner,
    uint256 _TGETimeStamp,
    uint256 _SECONDS_PER_MONTH
  ) MSPVesting(_token, _owner, _TGETimeStamp, 16, 0, (8 * _SECONDS_PER_MONTH), 6, _SECONDS_PER_MONTH) {}
}


/**
 * @dev MarketingMSPVesting will be unblocked 10% at TGE, then 5% monthly unlock.
 * Cliff is 0,
 * and the vestingDuration should be 18 months (18 * 5% = 90%).
 
 */
contract MarketingMSPVesting is MSPVesting {
  uint256 internal constant SECONDS_PER_DAY = 86400;
  constructor(
    address _token,
    address _owner,
    uint256 _TGETimeStamp,
    uint256 _SECONDS_PER_MONTH
  ) MSPVesting(_token, _owner, _TGETimeStamp, 18, 10, 0, 5, _SECONDS_PER_MONTH) {}
}

/**
 * @dev MSPVestingFactory is the main and is the only contract should be deployed.
 * Notice: remember to config the Token address and approriate startAtTimeStamp
 */
contract MSPVestingFactory {

  // put the token address here
  // This should be included in the contract for transparency
  address public MSP_TOKEN_ADDRESS = 0x5270556791Ae9f924a892A46DDd0b0b449281365;

  // put the startAtTimeStamp here
  // 1651240800 : Friday, April 29, 2022 2:00:00 PM UTC.
  // To test all contracts, change this timestamp to time in the past.
  uint256 public startAtTimeStamp = 1651240800;

  // Each month equals 30 days: 30*24*60*60 .Note: change this value to 300 to test on testnet
  uint256 internal constant _SECONDS_PER_MONTH = 2592000;

  // address to track other information
  address public owner;

  address public coreTeamMSPVesting;
  address public liquidityMSPVesting;
  address public reserveMSPVesting;
  address public marketingMSPVesting;

  constructor() {
    owner = msg.sender;

    CoreTeamMSPVesting _coreTeamMSPVesting = new CoreTeamMSPVesting(
      MSP_TOKEN_ADDRESS,
      owner,
      startAtTimeStamp,
      _SECONDS_PER_MONTH);
    coreTeamMSPVesting = address(_coreTeamMSPVesting);

    LiquidityMSPVesting _liquidityMSPVesting = new LiquidityMSPVesting(
      MSP_TOKEN_ADDRESS,
      owner,
      startAtTimeStamp,
      _SECONDS_PER_MONTH);
    liquidityMSPVesting = address(_liquidityMSPVesting);

    ReserveMSPVesting _reserveMSPVesting = new ReserveMSPVesting(
      MSP_TOKEN_ADDRESS,
      owner,
      startAtTimeStamp,
      _SECONDS_PER_MONTH);
    reserveMSPVesting = address(_reserveMSPVesting);

    MarketingMSPVesting _marketingMSPVesting = new MarketingMSPVesting(
      MSP_TOKEN_ADDRESS,
      owner,
      startAtTimeStamp,
      _SECONDS_PER_MONTH);
    marketingMSPVesting = address(_marketingMSPVesting);
  
  }
}
