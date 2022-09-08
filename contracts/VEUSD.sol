// SPDX-License-Identifier: MIT
// Power by: VeBank

pragma solidity ^0.8.0;

import './VIP180.sol';

contract VEUSD is VIP180 {
    constructor() VIP180("Vechain USD", "VEUSD") {
        _mint(msg.sender, 1000 * 10 ** 6 * (10 ** 6));
    }
    
    function decimals() public pure override returns (uint8) {
		return 6;
	}
}