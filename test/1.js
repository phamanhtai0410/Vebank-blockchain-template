const ethers = require('ethers');
const { ecsign } = require('ethereumjs-util');
const thor_devkit = require('thor-devkit');

const privateKey = "0x82cf6d5c367d249d5cbdf038cd6a4d35ebf7bd409face580cf5610088293a973";
// const privateKey = "0x0000000000000000000000000000000000000000000000000000000000000001";

async function test() {
    const _encode = ethers.utils.solidityPack(
        ["uint256", "uint256", "address", "uint256"],
        ["1", "0", "0xd1D5288E4E5984f6951C3283aCf3336687216Be2", "10000000000000000000"]
    )

    // const _encode = "0x00000000000000000000000000000000000000000000000000000000000000010000000000000000000000000000000000000000000000000000000000000000d1d5288e4e5984f6951c3283acf3336687216be20000000000000000000000000000000000000000000000008ac7230489e80000";
    const digest = ethers.utils.solidityKeccak256(["bytes"], [ethers.utils.solidityPack(
        ["uint256", "address", "uint256", "bytes"],
        ["97", "0x5DdBdfd5D5c4d121c33583BC8c6Eb93E16329ccC", "1694603717", _encode]
    )])

    console.log(digest)

    const { v, r, s } = ecsign(
        Buffer.from(digest.slice(2), 'hex'),
        Buffer.from(privateKey.slice(2), 'hex')
    )
    console.log(_encode)

    console.log(`[${v}, "${ethers.utils.hexlify(r)}", "${ethers.utils.hexlify(s)}", 1694603717]`)

}

test();




