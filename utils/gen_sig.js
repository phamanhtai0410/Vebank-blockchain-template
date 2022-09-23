const Web3 = require("web3");
const ethers = require('ethers');
const thor_devkit = require('thor-devkit');
const { ecsign } = require('ethereumjs-util');


module.exports =  async function gen_sig(sig_index, _index, _amount, _owner, _user, _chainName, _IDOcontract, _deadline) {
    /**
     *      Gen signature by owner address
     */

    // Read keystore
    var _keystore = JSON.parse(fs.readFileSync('test/tai_keystore'));
    console.log("*** Keystore : ", _keystore);

    // Decrypt keystore to private key
    var _private_key = await thor_devkit.Keystore.decrypt(_keystore, '21021997');
    _private_key = ethers.utils.hexlify(_private_key)
    console.log("*** Private Key : ", _private_key);

    // Encode signature data
    var _encode = Web3.utils.encodePacked(
        sig_index,  // uint(0x1)
        _index,
        _user,
        _amount
    ); 
    var _msg_full_hash = Web3.utils.keccak256(Web3.utils.encodePacked(
        _chainName,
        _IDOcontract,
        _deadline,
        _encode
    ))
    console.log("*** Encoded msg : ", _msg_full_hash);

    // Signature
    const { v, r, s } = ecsign(
        Buffer.from(_msg_full_hash.slice(2), 'hex'),
        Buffer.from(_private_key.slice(2), 'hex')
    )
    console.log("========================================================================================");
    console.log("====> Signature : ");
    console.log("+ proof.v : ", v);
    console.log("+ proof.r : ", Web3.utils.toHex(r));
    console.log("+ proof.s : ", Web3.utils.toHex(s));
    console.log("+ proof.deadline : ", _deadline);


    return {
        v: v,
        r: Web3.utils.toHex(r),
        s: Web3.utils.toHex(s),
        deadline: _deadline
    }
}


