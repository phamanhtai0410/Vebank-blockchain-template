// File: contracts/contracts-v2/LuaVesting.sol
//SPDX-License-Identifier: Unlicense
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;


import "./AccessControl.sol";


contract LuaVesting is AccessControl {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    address public IDOContract;

    struct UserInfo {
        uint256 amount;
        uint256 claimedAmount;
        uint256 claimAtsTime;
    }

    mapping(address => UserInfo) public info;
    address public idoToken;
    address[] public users;

    uint256[] public claimPercents;     //[20, 40, 40]
    uint256[] public claimAts;          //[A, B, C]

    constructor(address _owner, uint256[] memory _claimPercent, uint256[] memory _claimAts, address _idoToken) public AccessControl(_owner) {
        require(_claimAts.length == _claimPercent.length, "LuaVesting: Wrong data");
        uint s = 0;
        for (uint i = 0; i < _claimPercent.length; i++) {
            s += _claimPercent[i];
        }
        require(s == 100, "LuaVesting: Wrong percent");
        require(_claimAts[0] > 0, "LuaVesting: Wrong _claimAts[0]"); // TGE
        claimPercents = _claimPercent;
        claimAts = _claimAts;
        idoToken = _idoToken;
    }

    modifier onlyIDO() {
        require(msg.sender == IDOContract);
        _;
    }    

    function getVestingLength() public view returns (uint256) {
        return claimAts.length;
    }

    function setIDO(address _newIDO) external onlyOwner {
        require(_newIDO != address(0));
        IDOContract = _newIDO;
    }

    function _estimateClaim(address user, uint blockTime) private view returns (uint256 amount, uint256 claimAt) {
        amount = 0;
        UserInfo memory ui = info[user];

        claimAt = ui.claimAtsTime;

        for (uint i = 0; i < claimAts.length; i++) {
            uint b = claimAts[i];
            uint p = claimPercents[i];

            if (ui.claimAtsTime < b && b < blockTime) {
                if (i <= claimAts.length - 2) {
                    amount += ui.amount.mul(p).div(100);
                }
                else {
                    amount = ui.amount.sub(ui.claimedAmount);
                }
                claimAt = b;
            }
        }

        if (ui.claimedAmount.add(amount) > ui.amount) {
            amount = ui.amount.sub(ui.claimedAmount);
        }
    }

    function _claim(address user) private {
        UserInfo storage ui = info[user];
        require(ui.amount > 0, "LuaVesting: Wrong data");
        (uint amount, uint claimAt) = _estimateClaim(user, block.timestamp);

        ui.claimedAmount = ui.claimedAmount.add(amount);
        ui.claimAtsTime = claimAt;

        IERC20(idoToken).transfer(user, amount);
    }

    function vestingFor(address add, uint userAmount) public onlyIDO {
        UserInfo storage ui = info[add];
        if (ui.amount == 0) {
            users.push(add);
        }
        ui.amount = ui.amount.add(userAmount);
        _claim(add);
    }

    function claim() public {
        _claim(msg.sender);
    }

    function estimateClaim(address user, uint blockTime) public view returns (uint256 amount) {
        (amount, ) = _estimateClaim(user, blockTime);
    }

    function updateVesting(uint256[] memory _claimPercent, uint256[] memory _claimAts) public onlyOwner {
        require(_claimAts.length == _claimPercent.length, "LuaVesting: Wrong data");
        uint s = 0;
        for (uint i = 0; i < _claimPercent.length; i++) {
            s += _claimPercent[i];
        }
        require(s == 100, "LuaVesting: Wrong percent");
        require(_claimAts[0] > 0, "LuaVesting: Wrong _claimAts[0]"); // TGE
        claimPercents = _claimPercent;
        claimAts = _claimAts;
    }
}