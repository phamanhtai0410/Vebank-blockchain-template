var fs = require("fs")
const path = require("path");
require('dotenv').config({path: path.resolve(__dirname, "../.env")});
const WVET = artifacts.require("WVET");
const DEPLOY_NEW = false;

function wf(name, address) {
  fs.appendFileSync('.env', name + "=" + address);
  fs.appendFileSync('.env', "\r\n");
}

module.exports = async function (deployer) {
  if(DEPLOY_NEW){
  await deployer.deploy(WVET);
  var iWVET = await WVET.deployed();
  wf("iWVET", iWVET.address);
  console.log("iWVET: ", iWVET.address)
  } else {
    const iWVET = await WVET.at(process.env.iWVET);
    console.log("iWVET: ", iWVET.address)
  }
}
