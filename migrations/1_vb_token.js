var fs = require("fs")
const path = require("path");
require('dotenv').config({path: path.resolve(__dirname, "../.env")});
const VB = artifacts.require("VB");
const DEPLOY_NEW = false;

function wf(name, address) {
  fs.appendFileSync('.env', name + "=" + address);
  fs.appendFileSync('.env', "\r\n");
}

module.exports = async function (deployer) {
  if(DEPLOY_NEW){
  await deployer.deploy(VB);
  var iVB = await VB.deployed();
  wf("iVB", iVB.address);
  console.log("iVB: ", iVB.address)
  } else {
    const iVB = await VB.at(process.env.iVB);
    console.log("iVB: ", iVB.address)
  }
}
