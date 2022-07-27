var fs = require("fs")
const path = require("path");
require('dotenv').config({path: path.resolve(__dirname, "../.env")});
const VEUSD = artifacts.require("VEUSD");
const DEPLOY_NEW = false;

function wf(name, address) {
  fs.appendFileSync('.env', name + "=" + address);
  fs.appendFileSync('.env', "\r\n");
}

module.exports = async function (deployer) {
  if(DEPLOY_NEW){
  await deployer.deploy(VEUSD);
  var iVEUSD = await VEUSD.deployed();
  wf("iVEUSD", iVEUSD.address);
  console.log("iVEUSD: ", iVEUSD.address)
  } else {
    const iVEUSD = await VEUSD.at(process.env.iVEUSD);
    console.log("iVEUSD: ", iVEUSD.address)
  }
}
