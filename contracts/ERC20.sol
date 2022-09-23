// SPDX-License-Identifier: MIT
// Power by: Meta Super Pet

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/** Official Meta Super Pet token (MSP) smart-contract */

contract IDOToken is ERC20 {
    constructor() ERC20("IDO test Token", "IDOTT") {
        _mint(msg.sender, 500 * 10 ** 6 * (10 ** 18));
    }
}