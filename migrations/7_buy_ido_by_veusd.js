var fs = require("fs")
const path = require("path");
require('dotenv').config({path: path.resolve(__dirname, "../.env")});
const VEUSDIdo = artifacts.require("VEUSDIdo");
const VEUSD = artifacts.require("VEUSD");
const DEPLOY_NEW = false;

const _coinToken = process.env.iVEUSD; // VEUSD address 
const _idoStartAt = 1658894595 ; // Wednesday, July 27, 2022 4:03:15 AM
const _idoEndAt   = 1658980995 ; // Thursday, July 28, 2022 4:03:15 AM

function wf(name, address) {
  fs.appendFileSync('.env', name + "=" + address);
  fs.appendFileSync('.env', "\r\n");
}

module.exports = async function (deployer) {
  if(DEPLOY_NEW){
    await deployer.deploy(VEUSDIdo);
    var iVEUSDIdo = await VEUSDIdo.deployed();
    wf("iVEUSDIdo", iVEUSDIdo.address);
  } else {
    const iVEUSD = await VEUSD.at(process.env.iVEUSD);
    const iVEUSDIdo = await VEUSDIdo.at(process.env.iVEUSDIdo)
    async function approve_Pool(_amount){
      await iVEUSD.approve(process.env.iVEUSDIdo, _amount);
      console.log("Approved!")
    }
    async function buy(){
        await iVEUSDIdo.buy();
        console.log("bought!");
    }
    async function initialize(){
        if ((await iVEUSDIdo.coinToken.call()).toString() != "0x0000000000000000000000000000000000000000"){
            console.log("contract is already initialized")
        } else {
            await iVEUSDIdo.initialize(_coinToken,_idoStartAt,_idoEndAt);
            console.log("Success!")
        }
    }
    async function setWhitelist(_address, _amount){ 
        await iVEUSDIdo.setWhitelist(_address, _amount);
        console.log(`Address ${_address} has been add whitelist with amount ${_amount}`);

    }
    async function withdraw(){
        await iVEUSDIdo.withdraw();
        console.log("Pool has been withdrawn!")
    }
    async function transferOwner(_newOwner){
        await iVEUSDIdo.transferOwner(_newOwner);
    }   
    async function checkWhitelist(_address){
        let _amount = (await iVEUSDIdo.whiteList.call(_address)).toString();
        if (_amount == "0") {
            console.log("User not in IDO whitelist");
        } else {
        console.log(`Address ${_address} has been add whitelist with amount: `,_amount) ;
        }
    }
    // await iVEUSD.approve("0xE1bBEa38Cc95240680c2ab4940c9F202C90184BA", "10000000000000");
    // await console.log((iVEUSDIdo.enableIdo.call()).toString())
    // await approve_Pool("10000000000000");
    // await iVEUSD.transfer("0xE1bBEa38Cc95240680c2ab4940c9F202C90184BA","200000000");
    await buy();
    // let tata = (await iVEUSDIdo.idoUsers.call("0xE1bBEa38Cc95240680c2ab4940c9F202C90184BA")).buyAt.toString() ; 
    // console.log("amount", tata)
    // await withdraw();
    // await initialize();
    // await setWhitelist("0xE1bBEa38Cc95240680c2ab4940c9F202C90184BA","1000000000");
    // let a = (await iVEUSDIdo.idoValue.call()).toString();
    // console.log("ok", a )
    // await checkWhitelist("0xE1bBEa38Cc95240680c2ab4940c9F202C90184BA");
  }
};
