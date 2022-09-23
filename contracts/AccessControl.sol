// File: contracts/contracts-v2/AccessControl.sol
//SPDX-License-Identifier: Unlicense
pragma solidity ^0.6.12;

import "./SafeERC20.sol";

contract AccessControl {
    using SafeERC20 for IERC20;

    address payable public owner;

    event SetOperator(address indexed add, bool value);

    constructor(address _ownerAddress) public {
        owner = payable(_ownerAddress);
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function setOwner(address payable _newOwner) external onlyOwner {
        require(_newOwner != address(0));
        owner = _newOwner;
    }

    function emergencyWithdraw(address _token, address payable _to, uint256 amount) external onlyOwner {
        if (_token == address(0x0)) {
            amount = amount != 0 ? amount : address(this).balance;
            payable(_to).transfer(amount);
        }
        else {
            amount = amount != 0 ? amount : IERC20(_token).balanceOf(address(this));
            IERC20(_token).safeTransfer(_to, amount);
        }
    }
}