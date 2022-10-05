const LuaSwapIDO = artifacts.require("LuaSwapIDO");


module.exports = async function (deployer, network, accounts) {
    let account = deployer.options?.from || accounts[0];
    console.log("deployer = ", account);
    require('dotenv').config();


    var _swapIDO_instant = await LuaSwapIDO.at(process.env.SWAP_IDO_ADDRESS);

    /**
     *          1. Increase Cap
     */

    var index = 0;
    var _addAmountIDO = 1000000 * 10 ** 18;
    var _addAmountPay = 1000000 * 10 ** 18;

    await _swapIDO_instant.increaseCap(
        index,
        _addAmountIDO,
        _addAmountPay
    );

    /**
     *          2. Decrease Cap
     */
    
    var _subAmountIDO = 100000 * 10 ** 18;
    var _subAmountPay = 100000 * 10 ** 18;

    await _swapIDO_instant.decreaseCap(
        index,
        _subAmountIDO,
        _subAmountPay
    );

    /**
     *          3. Update Infos
     */


    var _minAmountPay = 1000 * 10 ** 18;
    var _maxAmountPay = 10000 * 10 ** 18;
    var _openAt = 1664065800; // 12h30 25/09/2022
    var _closeAt = 1664325000; // 12h30 28/09/2022
    var _claimAt = 1664411400; // 12h30 29/09/2022

    await _swapIDO_instant.updateInfo(
        index,
        _minAmountPay,
        _maxAmountPay,
        _openAt,
        _closeAt,
        _claimAt
    );

    
}