// SPDX-License-Identifier: MIT
// Power by: VeBank

pragma solidity ^0.8.0;

import "./BEP20.sol";

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

abstract contract TokenVesting is BEPOwnable {
  using SafeMath for uint256;

  // Address of VB Token.
  IERC20 public VBToken;

  // Starting timestamp of vesting
  // Will be used as a starting point for all dates calculations.
  // Can be set to TGE. In unix timestamp.
  uint256 public vestingStartAt;

  // Vesting duration in month
  uint256 public monthlyDuration;

  // Vesting duration in month
  uint256 public vestingMonths;

  // seconds each month. This number should be a constant, but we make it mutable for easy testing
  uint256 internal  SECONDS_PER_MONTH;

  // vestingCliff is the Cliff from vestingStartAt, in seconds
  uint256 public vestingCliff;


  // Percent of vested token which can be claimed at TGE;
  uint256 public percentClaimAtTGE;

  // When to start the month period
  uint256 public monthlyStartAt;

  // Beneficiary contains details of each beneficiary/investor
  struct Beneficiary {
    uint256 initialBalance;
    uint256 monthsClaimed;
    uint256 totalClaimed;
    uint256 claimedAtTGE; // indicate how much this Beneficiary already claimed at TGE
  }


  struct infoBeneficiary {
    address addressBeneficiary;
    uint256 initialBalance;
  }

  // beneficiaries tracks all beneficiary and store data in storage
  mapping(address => Beneficiary) public beneficiaries;

  infoBeneficiary[]  public listBeneficiaries ;

  // Event raised on each successful withdraw.xf
  event Claim(address beneficiary, uint256 amount, uint256 timestamp);

  // Event raised on each desposit
  event Deposit(address beneficiary, uint256 initialBalance, uint256 timestamp);

  // @dev constructor creates the vesting contract
  // @param _token Address of VB token
  // @param _owner Address of owner of this contract, a.k.a the CEO
  // @param _vestingStartAt the starting timestamp of vesting , in seconds.
  // @param _monthlyDuration the duration since monthlyStartAt until the vesting ends, in months.
  // @param _percentClaimAtTGE the percent of vested token that can be claimed after TGE. input 7 for 7%
  // @param _vestingCliff the cooldown period after _vestingStartAt, so that the monthly vesting will start, in seconds.
  // @param _secondPerMonth the second per month. Each month 30 days
  constructor(
    address _token,
    address _owner,
    uint256 _vestingStartAt,
    uint256 _monthlyDuration,
    uint256 _percentClaimAtTGE,
    uint256 _vestingCliff,
    uint256 _secondPerMonth
  ) {
    require(_token != address(0), "zero-address");
    require(_owner != address(0), "zero-address");
    require(_percentClaimAtTGE <= 100, "Invalid params");

    VBToken = IERC20(_token);
    _transferOwnership(_owner);
    vestingStartAt = _vestingStartAt;
    monthlyDuration = _monthlyDuration;
    percentClaimAtTGE = _percentClaimAtTGE;
    vestingCliff = _vestingCliff;
    SECONDS_PER_MONTH = _secondPerMonth;
    vestingMonths = _monthlyDuration ;
    monthlyStartAt = vestingStartAt.add(vestingCliff); // NOTE: the first monthly claim with be 1 month (SECONDS_PER_MONTH) AFTER this timestamp.
  }

  // @dev addBeneficiary registers a beneficiary and deposit a
  // corresponded amount of token for this beneficiary
  //
  // The owner can call this function many times to update
  // (additionally desposit) the amount of token for this beneficiary
  // @param _beneficiary Address of the beneficiary
  // @param _amount Amount of token belongs to this beneficiary
  function addBeneficiary(address _beneficiary, uint256 _amount) public onlyOwner {
    require(_beneficiary != address(0), "zero-address");
    // Based on ERC20 standard, to transfer funds to this contract,
    // the owner must first call approve() to allow to transfer token to this contract.
    require(VBToken.transferFrom(_msgSender(), address(this), _amount), "cannot-transfer-token-to-this-contract");

    // update storage data
    Beneficiary storage bf = beneficiaries[_beneficiary];
    bf.initialBalance = bf.initialBalance.add(_amount);
    infoBeneficiary memory lb;
    lb.addressBeneficiary = _beneficiary;
    lb.initialBalance = bf.initialBalance;
    listBeneficiaries.push(lb);

    emit Deposit(_beneficiary, bf.initialBalance, block.timestamp);
  }
  // function getListBeneficiaries(uint256 _index) public view onlyOwner returns(infoBeneficiary memory){
  //   return listBeneficiaries[_index];
  // }

  // @dev Claim withraws the vested token and sends beneficiary
  // Only the owner or the beneficiary can call this function
  // @param _beneficiary Address of the beneficiary
  function claimVestedToken(address _beneficiary) public {
    require(isOwner() || (_msgSender() == _beneficiary), "must-be-onwer-or-beneficiary");
    uint256 monthsVestable;
    uint256 tokenVestable;
    uint256 tokenClaimedAtTGE;
    uint256 _nextClaimable;
    Beneficiary storage bf = beneficiaries[_beneficiary];
    require(bf.initialBalance > bf.totalClaimed, "nothing-to-be-vested");
    
    (monthsVestable, tokenVestable, tokenClaimedAtTGE, _nextClaimable) = calculateClaimable(_beneficiary);
    require(tokenVestable > 0, "nothing-to-be-vested");

    require(VBToken.transfer(_beneficiary, tokenVestable), "fail-to-transfer-token");

    // update data in blockchain storage
    bf.monthsClaimed = bf.monthsClaimed.add(monthsVestable);
    bf.totalClaimed = bf.totalClaimed.add(tokenVestable);

    // check it to save the gas for writing
    if (bf.claimedAtTGE == 0) {
      bf.claimedAtTGE = tokenClaimedAtTGE;
    }

    emit Claim(_beneficiary, tokenVestable, block.timestamp);
  }

  // calculateWithrawable calculates the claimable token of the beneficiary
  // claimable token each month is rounded if it is a decimal number
  // So the rest of the token will be claimed on the last month (the duration is over)
  // @param _beneficiary Address of the beneficiary
  function calculateClaimable(address _beneficiary) private view returns (uint256, uint256, uint256, uint256) {
    uint256 _now = block.timestamp;
    uint256 _nextClaimable = vestingStartAt;
    // return 0 for any claim before the starting time
    if (_now < vestingStartAt) {
      return (0, 0, 0,_nextClaimable);
    }
    _nextClaimable = monthlyStartAt + SECONDS_PER_MONTH;
    uint256 _tokenClaimable;
    uint256 _tokenClaimedAtTGE; 

    Beneficiary storage bf = beneficiaries[_beneficiary];
    require(bf.initialBalance > 0, "beneficiary-not-found");


    _tokenClaimedAtTGE = bf.initialBalance.mul(percentClaimAtTGE).div(100);

    // if the user has not ever claimed his _tokenClaimedAtTGE, add that amount to be claimed
    if (bf.claimedAtTGE == 0) {
      _tokenClaimable =  _tokenClaimable.add(_tokenClaimedAtTGE);
    }

    if (_now < monthlyStartAt) {

      return (0, _tokenClaimable, _tokenClaimedAtTGE, _nextClaimable);
    }

    uint256 elapsedTime = _now.sub(monthlyStartAt);
    uint256 elapsedMonths = elapsedTime.div(SECONDS_PER_MONTH);

    // If it does not pass the first month yet
    if (elapsedMonths < 1) {
      return (0, _tokenClaimable, _tokenClaimedAtTGE, _nextClaimable);
    }

    // If over vesting duration, get all remain tokens
    if (elapsedMonths >= monthlyDuration) {
      uint256 remaining = bf.initialBalance.sub(bf.totalClaimed);
      return (monthlyDuration.sub(bf.monthsClaimed), remaining, _tokenClaimedAtTGE, _nextClaimable);
    } else {
      _nextClaimable = _nextClaimable + SECONDS_PER_MONTH.mul(elapsedMonths);
      uint256 _amountForMonthly = bf.initialBalance.sub(_tokenClaimedAtTGE);
      uint256 _monthsClaimedable = elapsedMonths.sub(bf.monthsClaimed);
      uint256 _amountClaimedablePerMonth = _amountForMonthly.div(vestingMonths);
      _tokenClaimable = _tokenClaimable + _monthsClaimedable.mul(_amountClaimedablePerMonth);
      return (_monthsClaimedable, _tokenClaimable, _tokenClaimedAtTGE, _nextClaimable);
    }
  }

  // view function to check status of a beneficiary
  function getBeneficiary(address _beneficiary)
    public
    view
    returns (
      uint256 initialBalance,
      uint256 monthsClaimed,
      uint256 totalClaimed,
      uint256 claimedAtTGE,
      uint256 tokenClaimable,
      uint256 nextClaimable
    )
  {
    Beneficiary storage bf = beneficiaries[_beneficiary];
    require(bf.initialBalance > 0, "beneficiary-not-found");

    uint256 _monthsClaimable;
    uint256 _tokenClaimable;
    uint256 _tokenClaimedAtTGE;
    uint256 _nextClaimable ;
    (_monthsClaimable, _tokenClaimable, _tokenClaimedAtTGE,_nextClaimable) = calculateClaimable(_beneficiary);

    return (bf.initialBalance, bf.monthsClaimed, bf.totalClaimed, bf.claimedAtTGE, _tokenClaimable,_nextClaimable);
  }

  // @dev function for emergency, withraw all token in this vesting contract to the owner wallet
   function withdrawAll() external onlyOwner {
        VBToken.transfer(_msgSender(), VBToken.balanceOf(address(this)));
    }

  // @dev function for emergency, withraw token of a beneficiary to the owner wallet
   function withdrawBeneficiary(address _beneficiary) external onlyOwner {

        // VBToken.transfer(_msgSender(), VBToken.balanceOf(address(_beneficiary)));
        Beneficiary storage bf = beneficiaries[_beneficiary];
        uint256 remaining = bf.initialBalance.sub(bf.totalClaimed);

        // send remaining token to the owner
        VBToken.transfer(_msgSender(), remaining);

        // update data of this beneficiary, so the owner cannot withraw this amount again.
        bf.totalClaimed = bf.initialBalance;

    }
  
}

