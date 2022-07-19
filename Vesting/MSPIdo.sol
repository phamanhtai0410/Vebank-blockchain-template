// SPDX-License-Identifier: MIT
// Power by: Meta Super Pet

pragma solidity ^0.8.2;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * User buy IDO (public sale) using BUSD on Dapp.
 * Maximum 1,000,000 token release for IDO on Dapp. Each user buy fixed 100 BUSD.
 * Whitelist user will buy first, then FCFS until sale out 1,000,000 token.
 * After buy, token will be release in smartcontract MSPPublicSaleVesting with 20% at TGE, then 16% monthly.
 */

contract MSPIdo is
    AccessControlUpgradeable,
    OwnableUpgradeable {

    using SafeMath for uint256;

    event BuyIdo(address indexed user, uint256 amount, uint256 buyAt);

    bytes32 public constant DESIGNER_ROLE = keccak256("DESIGNER_ROLE");
    bytes32 public constant WHITELIST_ROLE = keccak256("WHITELIST_ROLE");

    uint public constant TOKEN_DECIMALS = 10 ** 18;
    // Each user can buy fixed value. 100 * TOKEN_DECIMALS for 100 BUSD
    uint256 public constant AMOUNT_PER_USER = 100 * TOKEN_DECIMALS;
    // Maximum BUSD after token sold out on dapp. 45000 * TOKEN_DECIMALS for  45,000 BUSD.
    uint256 public constant MAX_IDO_VALUE = 45000 * TOKEN_DECIMALS;

    // BUSD addr
    IERC20 public coinToken;

    // IDO control
    uint256 public idoStartAt;
    uint256 public idoEndAt;
    bool public enableIdo;
    uint256 public idoValue;
    // FCFS control.
    bool public enableFcfs;
    uint256 public fcfsTotal;

    // Info of each place order.
    struct UserIdoInfo {
        uint256 amount;
        uint256 buyAt;
    }


    // Mapping addr to user ido info.
    mapping(address => UserIdoInfo) public idoUsers;

    // Mapping whitelist addresses to buyable amount
    mapping(address => uint256) public whiteList;

    /**
     * @notice Checks if the msg.sender is a contract or a proxy
     */
    modifier notContract() {
        require(!_isContract(msg.sender), "Contract not allowed");
        require(msg.sender == tx.origin, "Proxy contract not allowed");
        _;
    }

    /**
    * @param _coinToken input valid addr MSP.
    * @param _idoStartAt input 1651140000 for 28/04/2022 10:00:00 UTC.
    * @param _idoEndAt input 1651168800, after 8h from start time.
    */
    function initialize(
        IERC20 _coinToken,
        uint256 _idoStartAt,
        uint256 _idoEndAt
    ) public initializer {
        __AccessControl_init();

        coinToken = _coinToken;
        idoStartAt = _idoStartAt;
        idoEndAt = _idoEndAt;
        enableIdo = true;
        enableFcfs = false;

        _transferOwnership(msg.sender);
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(DESIGNER_ROLE, msg.sender);
        _setupRole(WHITELIST_ROLE, msg.sender);
    }

    /** Control enable/diable IDO */
    function setEnableIdo(bool _enableIdo) external onlyRole(DESIGNER_ROLE) {
        enableIdo = _enableIdo;
    }

    /** Control enable/disable FCFS */
    function setEnableFcfs(bool _enableFcfs) external onlyRole(DESIGNER_ROLE) {
        enableFcfs = _enableFcfs;
    }

    // function setIdoStartAt(uint256 _idoStartAt) external onlyRole(DESIGNER_ROLE) {
    //     idoStartAt = _idoStartAt;
    // }

    function setIdoEndAt(uint256 _idoEndAt) external onlyRole(DESIGNER_ROLE) {
        idoEndAt = _idoEndAt;
    }


    /** Set whitelist addresses and amount.
    If set after addr whitelistMint tokens, amount will be reset to input amount. */
    function setWhitelist(address addr, uint256 amount) external onlyRole(WHITELIST_ROLE) {
        whiteList[addr] = amount;
    }

    /** Buy deposit and wait for release at TGE.*/
    function buy() external notContract {
        address to = msg.sender;
        require(enableIdo, "IDO not enable");
        require(idoStartAt < block.timestamp, "IDO has not start yet");
        require(idoEndAt > block.timestamp, "IDO has ended");

        if (enableFcfs == false) {
            // User need in whitelist to place order.
            require(whiteList[to] >= AMOUNT_PER_USER, "User not in IDO whitelist");
        }
        require(idoValue + AMOUNT_PER_USER <= MAX_IDO_VALUE, "IDO sold out");
        require(idoUsers[to].amount == 0, "User already bought");
                
        address owner = address(this);
        
        // Transfer token
        coinToken.transferFrom(to, owner, AMOUNT_PER_USER);

        UserIdoInfo memory userIdoInfo;
        userIdoInfo.amount = AMOUNT_PER_USER;
        userIdoInfo.buyAt = block.timestamp;
        idoUsers[to] = userIdoInfo;

        idoValue += AMOUNT_PER_USER;
        if (enableFcfs) {
            fcfsTotal += AMOUNT_PER_USER;
        }

        emit BuyIdo(to, AMOUNT_PER_USER, block.timestamp);
    }

    /** Only use for emergency case. */
    function withdraw() external onlyRole(DEFAULT_ADMIN_ROLE) {
        coinToken.transfer(msg.sender, coinToken.balanceOf(address(this)));
    }

    /**
     * @notice Checks if address is a contract
     * @dev It prevents contract from being targetted
     */

    function _isContract(address addr) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(addr)
        }
        return size > 0;
    }
}
