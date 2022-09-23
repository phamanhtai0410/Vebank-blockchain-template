// SPDX-License-Identifier: MIT
// Power by: Meta Super Pet

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/** Official Meta Super Pet token (MSP) smart-contract */

contract MSP is ERC20 {
    constructor() ERC20("Meta Super Pet", "MSP") {
        _mint(msg.sender, 500 * 10 ** 6 * (10 ** 18));
    }
}
