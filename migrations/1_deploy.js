const Vesting = artifacts.require("LuaVesting");
const LuaSwapIDO = artifacts.require("LuaSwapIDO");
const ERC20 = artifacts.require("IDOToken");
const wf = require("../utils/file.js");


const IS_DEPLOY_NEW = {
    idoToken: true,
    vesting: true,
    swapIDO: true
};

module.exports = async function (deployer, network, accounts) {
    let account = deployer.options?.from || accounts[0];
    console.log("deployer = ", account);
    require('dotenv').config();


    var _owner = account;

    /**
     *          0. Deploy IDO Token
     */
    if (IS_DEPLOY_NEW.idoToken) {
        // IDO token
        await deployer.deploy(ERC20);
        var _idoToken_instant = await ERC20.deployed();
        wf("IDOToken", _idoToken_instant.address);
        // Pay token
        await deployer.deploy(ERC20);
        var _payToken_instant = await ERC20.deployed();
        wf("PayToken", _payToken_instant.address);

    }
    else {
        var _idoToken_instant = await ERC20.at(process.env.IDOToken);
        var _payToken_instant = await ERC20.at(process.env.PayToken);
    }

    var _idoToken = _idoToken_instant.address;
    var _payToken = _payToken_instant.address;

    /**
     *          1. Deploy Vesting contract
     */
    

    var _claimPercent = [
        20, 
        40, 
        40
    ];

    var _claimAts = [
        1663842600,
        1663846200,
        1663849800
    ];

    if (IS_DEPLOY_NEW.vesting) {
        await deployer.deploy(
            Vesting,
            _owner,
            _claimPercent,
            _claimAts,
            _idoToken
        );

        var _vesting_instant = await Vesting.deployed();

        wf("VESTING_ADDRESS", _vesting_instant.address);
    }
    else {
        var _vesting_instant = await Vesting.at(process.env.VESTING_ADDRESS);
    }


    /**
     *          2. Deploy Swap IDO
     */
    
    
    var _vesting = _vesting_instant.address;
    var _signer = _owner;
    var _signerClaim = _owner;

    if (IS_DEPLOY_NEW.swapIDO) {
        await deployer.deploy(
            LuaSwapIDO,
            _owner,
            _vesting,
            _signer,
            _signerClaim
        );
        var _swapIDO_instant = await LuaSwapIDO.deployed();
        wf("SWAP_IDO_ADDRESS", _swapIDO_instant.address);
    }
    else {
        var _swapIDO_instant = await LuaSwapIDO.at(process.env.SWAP_IDO_ADDRESS);
    }

    /**
     *          3. Map IDO contract to vesting
     */

    if (IS_DEPLOY_NEW.swapIDO) {
        await _vesting_instant.setIDO(
            _swapIDO_instant.address
        );
    }
    
    /**
     *          4. Set Chain Name for Swap IDO contract
     */
    if (IS_DEPLOY_NEW.swapIDO) {
        await _swapIDO_instant.setChainName("VeChain-testnet");
    }

    /**
     *          5. Config IDO contract with index
     */
    
    var _creator = _owner;
    var _totalAmountIdo = "1000000000000000000000000";
    var _totalAmountPay = "1000000000000000000000000";
    var _minAmountPay = "100000000000000000000";
    var _maxAmountPay = "1000000000000000000000";
    var _openAt = 1664065800; // 12h30 25/09/2022
    var _closeAt = 1664325000; // 12h30 28/09/2022
    var _claimAt = 1664411400; // 12h30 29/09/2022

    await _swapIDO_instant.createIDO(
        _creator,
        _idoToken,
        _payToken,
        _totalAmountIdo,
        _totalAmountPay,
        _minAmountPay,
        _maxAmountPay,
        _openAt,
        _closeAt,
        _claimAt
    );

}