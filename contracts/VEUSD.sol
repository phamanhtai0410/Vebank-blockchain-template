// SPDX-License-Identifier: MIT
// Power by: VeBank

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract VEUSD is ERC20 {
    constructor() ERC20("Vechain USD", "VEUSD") {
        _mint(msg.sender, 1000 * 10 ** 6 * (10 ** 6));
    }
    
    function decimals() public pure override returns (uint8) {
		return 6;
	}
}