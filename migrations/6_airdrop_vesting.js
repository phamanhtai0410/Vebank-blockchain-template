var fs = require("fs")
const path = require("path");
const { exit } = require("process");
require('dotenv').config({path: path.resolve(__dirname, "../.env")});
const VBAirdrop = artifacts.require("VBAirdrop");
const VB = artifacts.require("VB");
const DEPLOY_NEW = false;

const _TOKEN_ADDRESS = process.env.iVB; // VeBank address 
const _startAtTimeStamp = 1658735404 ; // Monday, July 25, 2022 7:50:04 AM
const _SECONDS_PER_MONTH = 2592000 ; // Each month equals 30 days: 30*24*60*60 .Note: change this value to 300 to test on testnet

function wf(name, address) {
  fs.appendFileSync('.env', name + "=" + address);
  fs.appendFileSync('.env', "\r\n");
}

module.exports = async function (deployer) {
  if(DEPLOY_NEW){
  await deployer.deploy(VBAirdrop, _TOKEN_ADDRESS, _startAtTimeStamp, _SECONDS_PER_MONTH);
  var iVBAirdrop = await VBAirdrop.deployed();
  wf("iVBAirdrop", iVBAirdrop.address);
  } else {
    const iVB = await VB.at(process.env.iVB);
    const iVBAirdrop = await VBAirdrop.at(process.env.iVBAirdrop)
    async function approve_Pool(_amount){
      await iVB.approve(process.env.iVBAirdrop, _amount);
      console.log("Approved!")
    }
    async function add_Beneficiary(_beneficiary, _amount ){
      await iVBAirdrop.addBeneficiary(_beneficiary, _amount );
      console.log("Beneficiary: ",_beneficiary);
    }
    async function revoke_Beneficiary(_beneficiary){

      await iVBAirdrop.withdrawBeneficiary(_beneficiary);
      console.log("revoked beneficiary: ", _beneficiary);
    }

    async function claim_Token(_beneficiary){
      
      await iVBAirdrop.claimVestedToken(_beneficiary);
      console.log("claimed!")
    }
    async function transfer_Ownership(_newOwner){
      await iVBAirdrop.transferOwnership(_newOwner);
      console.log("Transfer new Owner is: ", _newOwner );
    }
    async function withdraw_All(){
      await iVBAirdrop.withdrawAll();
      console.log("Withdraw all!")

    }
    async function get_Beneficiary(_beneficiary){
      
      let {initialBalance, monthsClaimed, totalClaimed,claimedAtTGE, tokenClaimable}  = await iVBAirdrop.getBeneficiary(_beneficiary);
      console.log("info initialBalance : ", initialBalance.toString());
      console.log("info monthsClaimed : ", monthsClaimed.toString());
      console.log("info totalClaimed : ", totalClaimed.toString());
      console.log("info claimedAtTGE : ", claimedAtTGE.toString());
      console.log("info claimClaimable : ", tokenClaimable.toString());
    }

    async function get_List_Beneficiaries(_index){
      // let len = (await iVBAirdrop.listBeneficiaries.call().length())
      // console.log("length: " , len)
      let addressBeneficiary =  (await iVBAirdrop.listBeneficiaries.call(_index)).addressBeneficiary;
      let initialBalance =  (await iVBAirdrop.listBeneficiaries.call(_index)).initialBalance.toString();
      console.log("addressBeneficiary: ", addressBeneficiary)
      console.log("initialBalance: ",initialBalance)
    }
    // await approve_Pool("1000000000000000000000000000");
    // await add_Beneficiary("0xc7ec10140ec58898de48d2078C6805A3a07c32c3","1100000000000000000")
    // await get_Beneficiary("0xc7ec10140ec58898de48d2078C6805A3a07c32c3");
    // await add_Beneficiary("0xE1bBEa38Cc95240680c2ab4940c9F202C90184BA","16000000000000000000")
    await get_Beneficiary("0xE1bBEa38Cc95240680c2ab4940c9F202C90184BA");
    //await add_Beneficiary("0x9a773a0c1710a5afd9d25eb5b0d2dca2239663e6","13000000000000000000")
    //await add_Beneficiary("0x146b47ba01cd21e8c2db6a7a305cbea3aa70783e","14000000000000000000")
    //await add_Beneficiary("0xf44d0fdb0c02b8683aCf300a7a892a30aCb17d84","16000000000000000000")
    //await get_Beneficiary("0xf44d0fdb0c02b8683aCf300a7a892a30aCb17d84");
    //await claim_Token("0xE1bBEa38Cc95240680c2ab4940c9F202C90184BA");
    //await withdraw_All();
    //await console.log("beneficiary 1: " , await iPublicSaleVBVesting.listBeneficiaries())
    //await const {a,b} = test;
    //await console.log(a)
    //await get_List_Beneficiaries(7)

  }
};
