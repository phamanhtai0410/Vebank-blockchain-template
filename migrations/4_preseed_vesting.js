var fs = require("fs")
const path = require("path");
require('dotenv').config({path: path.resolve(__dirname, "../.env")});
const PreSeedVBVesting = artifacts.require("PreSeedVBVesting");
const VB = artifacts.require("VB");
const DEPLOY_NEW = true;

const _TOKEN_ADDRESS = process.env.iVB; // VeBank address 
const _startAtTimeStamp = 1658979170 ; // Thursday, July 28, 2022 3:32:50 AM
const _SECONDS_PER_MONTH = 60 ; // Each month equals 30 days: 30*24*60*60 .Note: change this value to 300 to test on testnet 

function wf(name, address) {
  fs.appendFileSync('.env', name + "=" + address);
  fs.appendFileSync('.env', "\r\n");
}

module.exports = async function (deployer) {
  if(DEPLOY_NEW){
  await deployer.deploy(PreSeedVBVesting, _TOKEN_ADDRESS, _startAtTimeStamp, _SECONDS_PER_MONTH);
  var iPreSeedVBVesting = await PreSeedVBVesting.deployed();
  wf("iPreSeedVBVesting", iPreSeedVBVesting.address);
  } else {
    const iVB = await VB.at(process.env.iVB);
    const iPreSeedVBVesting = await PreSeedVBVesting.at(process.env.iPreSeedVBVesting)
    async function approve_Pool(_amount){
      await iVB.approve(process.env.iPreSeedVBVesting, _amount);
      console.log("Approved!")
    }
    // to add Beneficiary must be approve contract, call approve_Pool(_amount)
    async function add_Beneficiary(_beneficiary, _amount ){
      await iPreSeedVBVesting.addBeneficiary(_beneficiary, _amount );
      console.log(`Beneficiary ${_beneficiary} has been added with amount: ${_amount}`);
    }
    async function revoke_Beneficiary(_beneficiary){

      await iPreSeedVBVesting.withdrawBeneficiary(_beneficiary);
      console.log("revoked beneficiary: ", _beneficiary);
    }

    async function claim_Token(_beneficiary){
      
      await iPreSeedVBVesting.claimVestedToken(_beneficiary);
      console.log("claimed!")
    }
    async function transfer_Ownership(_newOwner){
      await iPreSeedVBVesting.transferOwnership(_newOwner);
      console.log("Transfer new Owner is: ", _newOwner );
    }
    async function withdraw_All(){
      await iPreSeedVBVesting.withdrawAll();
      console.log("Withdraw all!")

    }
    async function get_Beneficiary(_beneficiary){
      
      let {initialBalance, monthsClaimed, totalClaimed,claimedAtTGE, tokenClaimable}  = await iPreSeedVBVesting.getBeneficiary(_beneficiary);
      console.log("info initialBalance : ", initialBalance.toString());
      console.log("info monthsClaimed : ", monthsClaimed.toString());
      console.log("info totalClaimed : ", totalClaimed.toString());
      console.log("info claimedAtTGE : ", claimedAtTGE.toString());
      console.log("info claimClaimable : ", tokenClaimable.toString());
    }
    async function get_List_Beneficiaries(_index){
      // let len = (await iPreSeedVBVesting.listBeneficiaries.call().length())
      // console.log("length: " , len)
      for (let id =0 ; id < _index; id++){
        let addressBeneficiary =  (await iPreSeedVBVesting.listBeneficiaries.call(id)).addressBeneficiary;
        let initialBalance =  (await iPreSeedVBVesting.listBeneficiaries.call(id)).initialBalance.toString();
        console.log(`Beneficiary ${addressBeneficiary} has initial Balance: ${initialBalance}`)
      }
      
    }
    await approve_Pool("100000000000000000000000");
    // await add_Beneficiary("0xc7ec10140ec58898de48d2078C6805A3a07c32c3","101000000000000000000")
    // await add_Beneficiary("0x3afa0314a9c8748b64ed93ee6b413a5797ed9aef","102000000000000000000")
    // await add_Beneficiary("0x9a773a0c1710a5afd9d25eb5b0d2dca2239663e6","103000000000000000000")
    // await add_Beneficiary("0x146b47ba01cd21e8c2db6a7a305cbea3aa70783e","104000000000000000000")
    // await add_Beneficiary("0xE1bBEa38Cc95240680c2ab4940c9F202C90184BA","105000000000000000000")
    //await get_Beneficiary("0xc7ec10140ec58898de48d2078C6805A3a07c32c3");
    
    // await get_Beneficiary("0xE1bBEa38Cc95240680c2ab4940c9F202C90184BA");
    // await claim_Token("0xE1bBEa38Cc95240680c2ab4940c9F202C90184BA");
    //await withdraw_All();
    //await console.log("beneficiary 1: " , await iPublicSaleVBVesting.listBeneficiaries())
    //await const {a,b} = test;
    //await console.log(a)
    await get_List_Beneficiaries(50)

  }
};


