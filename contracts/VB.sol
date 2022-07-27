// SPDX-License-Identifier: MIT
// Power by: VeBank

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/** Official VeBank token (VB) smart-contract */

contract VB is ERC20 {
    constructor() ERC20("VeBank Token", "VB") {
        _mint(msg.sender, 500 * 10 ** 6 * (10 ** 18));
    }
}