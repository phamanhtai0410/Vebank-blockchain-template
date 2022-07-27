var fs = require("fs")
const path = require("path");
require('dotenv').config({path: path.resolve(__dirname, "../.env")});
const WVETIdo = artifacts.require("WVETIdo");
const WVET = artifacts.require("WVET");
const DEPLOY_NEW = false;

const _coinToken = process.env.iWVET; // VeBank address 
const _idoStartAt = 1658735404 ; // Monday, July 25, 2022 7:50:04 AM
const _idoEndAt = 1658835404 ; 

function wf(name, address) {
  fs.appendFileSync('.env', name + "=" + address);
  fs.appendFileSync('.env', "\r\n");
}

module.exports = async function (deployer) {
  if(DEPLOY_NEW){
  await deployer.deploy(WVETIdo);
  var iWVETIdo = await WVETIdo.deployed();
  wf("iWVETIdo", iWVETIdo.address);
  } else {
    const iWVET = await WVET.at(process.env.iWVET);
    const iWVETIdo = await WVETIdo.at(process.env.iWVETIdo)
    async function approve_Pool(_amount){
      await iWVET.approve(process.env.iWVETIdo, _amount);
      console.log("Approved!")
    }
    async function buy(){
        await iWVETIdo.buy();
        console.log("bought!");
    }
    async function initialize(){
        if ((await iWVETIdo.coinToken.call()).toString() != "0x0000000000000000000000000000000000000000"){
            console.log("contract is already initialized")
        } else {
            await iWVETIdo.initialize(_coinToken,_idoStartAt,_idoEndAt);
            console.log("Success!")
        }
    }
    async function setWhitelist(_address, _amount){ 
        await iWVETIdo.setWhitelist(_address, _amount);
        console.log(`Address ${_address} has been add whitelist with amount ${_amount}`);

    }
    async function withdraw(){
        await iWVETIdo.withdraw();
        console.log("Pool has been withdrawn!")
    }
    async function transferOwner(_newOwner){
        await iWVETIdo.transferOwner(_newOwner);
    }   
    async function checkWhitelist(_address){
      let _amount = (await iWVETIdo.whiteList.call(_address)).toString();
      if (_amount == "0") {
          console.log("User not in IDO whitelist");
      } else {
      console.log(`Address ${_address} has been add whitelist with amount: `,_amount) ;
      }
  }

    // await approve_Pool("100000000000");
    await initialize();

  }
};
