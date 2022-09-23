// File: contracts/contracts-v2/LuaSwapIDO.sol
//SPDX-License-Identifier: Unlicense
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "./AccessControl.sol";
import "./LuaVesting.sol";


contract LuaSwapIDO is AccessControl {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    struct Proof {
        uint8 v;
        bytes32 r;
        bytes32 s;
        uint256 deadline;
    }

    struct IDO {
        address payable creator;
        address idoToken;
        address payToken;
        uint256 totalAmountIDO;
        uint256 totalAmountPay;
        uint256 minAmountPay;
        uint256 maxAmountPay;
        uint256 openAt;
        uint256 closeAt;
        uint256 claimAt;
        uint256 swappedAmountIDO;
        uint256 swappedAmountPay;
        uint256 totalCommittedAmount;
    }

    IDO[] public IDOs;

    // address of user > pool id > value
    mapping(uint256 => address[]) public userCommited;
    mapping(address => mapping(uint256 => uint256)) public userCommitedAmount;
    mapping(address => mapping(uint256 => uint256)) public userSwappedAmountIDO;
    mapping(address => mapping(uint256 => uint256)) public userSwappedAmountPay;

    address public signer;
    address public signerClaim;
    LuaVesting public vesting;

    string public chainName;

    event EncodeMessage(bytes encodeData);

    event CreateIDO(uint256 indexed index, address indexed sender, IDO ido);
    event Commit(
        uint256 indexed index,
        address indexed sender,
        uint256 amountPay
    );
    event RemoveCommitment(
        uint256 indexed index,
        address indexed sender,
        uint256 amountPay
    );
    event CreatorClaim(
        uint256 indexed index,
        address indexed sender,
        uint256 amountIDO
    );
    event UserClaim(
        uint256 indexed index,
        address indexed sender,
        uint256 amountIDO
    );

    constructor(address _owner, address _vesting, address _signer, address _signerClaim) public AccessControl(_owner)  {
        vesting = LuaVesting(_vesting);
        signer = _signer;
        signerClaim = _signerClaim;
    }

    function setVesting(address _newVesting) external onlyOwner {
        vesting = LuaVesting(_newVesting);
    }        

    modifier isOpening(uint256 index) {
        IDO memory ido = IDOs[index];
        require(
            ido.openAt <= block.timestamp && block.timestamp < ido.closeAt,
            "POOL SHOULD BE OPENED"
        );
        _;
    }

    modifier notOpen(uint256 index) {
        IDO memory ido = IDOs[index];
        require(
            block.timestamp < ido.openAt,
            "POOL SHOULD BE NOT OPEN"
        );
        _;
    }

    modifier closed(uint256 index) {
        require(
            IDOs[index].closeAt <= block.timestamp,
            "POOL SHOULD BE CLOSED"
        );
        _;
    }

    modifier canClaim(uint256 index) {
        require(
            IDOs[index].claimAt == 0 || IDOs[index].claimAt <= block.timestamp,
            "CANNOT CLAIM"
        );
        _;
    }

    modifier existIDO(uint256 index) {
        require(index < IDOs.length, "POOL SHOULD EXIST");
        _;
    }

    function setChainName(string memory _chainName) external onlyOwner {
        chainName = _chainName;
    }

    function getChainName() internal view returns (string memory) {
        return chainName;
    }

    function verifyProof(address _signer, bytes memory _encode, Proof memory _proof) public view returns (bool) {
        if (_signer == address(0x0)) {
            return true;
        }
        bytes32 digest = keccak256(abi.encodePacked(getChainName(), address(this), _proof.deadline, _encode));
        address signatory = ecrecover(digest, _proof.v, _proof.r, _proof.s);
        return signatory == _signer && _proof.deadline >= block.timestamp;
    }

    function verifyProofSigner(address _signer, bytes memory _encode, Proof memory _proof) public view returns (bool) {
        if (_signer == address(0x0)) {
            return true;
        }
        bytes32 digest = keccak256(abi.encodePacked(getChainName(), address(this), _proof.deadline, _encode));
        address signatory = ecrecover(digest, _proof.v, _proof.r, _proof.s);
        return signatory == _signer;
    }

    function verifyProofTime(address _signer,Proof memory _proof) public view returns (bool) {
        if (_signer == address(0x0)) {
            return true;
        }
        return _proof.deadline >= block.timestamp;
    }

    function verifyProoftoAddr(address _signer, bytes memory _encode, Proof memory _proof) public view returns (address) {
        if (_signer == address(0x0)) {
            return _signer;
        }
        bytes32 digest = keccak256(abi.encodePacked(getChainName(), address(this), _proof.deadline, _encode));
        address signatory = ecrecover(digest, _proof.v, _proof.r, _proof.s);
        return signatory;
    }

    function numberOfIDO() public view returns (uint256) {
        return IDOs.length;
    }

    function numberOfUserCommitted(uint idoIndex) public view returns (uint256) {
        return userCommited[idoIndex].length;
    }

    function listUserCommitted(uint idoIndex) public view returns (address[] memory) {
        return userCommited[idoIndex];
    }

    function setSigner(address _signer) public onlyOwner {
        signer = _signer;
    }

    function setSignerClaim(address _signer) public onlyOwner {
        signerClaim = _signer;
    }

    function transferHelper(
        address token,
        address payable add,
        uint256 amount
    ) private {
        if (token == address(0)) {
            add.transfer(amount);
        } else {
            IERC20(token).transfer(add, amount);
        }
    }

    function createIDO(
        address payable creator,
        address idoToken,
        address payToken,
        uint256 totalAmountIDO,
        uint256 totalAmountPay,
        uint256 minAmountPay,
        uint256 maxAmountPay,
        uint256 openAt,
        uint256 closeAt,
        uint256 claimAt
    ) public onlyOwner {
        require(idoToken != address(0), "idoToken is wrong");
        require(
            idoToken != payToken,
            "idoToken AND payToken SHOULD BE DIFFERENT"
        );
        require(totalAmountIDO != 0, "INVALID TOTAL AMOUNT OF totalAmountIDO");
        require(totalAmountPay != 0, "INVALID TOTAL AMOUNT OF totalAmountPay");
        // require(totalAmountIDO % totalAmountPay == 0,"NOT INTEGER RATIO");

        require(
            minAmountPay <= maxAmountPay,
            "INVALID minAmountPay AND maxAmountPay"
        );

        require(openAt > block.timestamp, "INVALID OPEN_AT");
        require(closeAt > openAt, "INVALID CLOSE_AT");
        require(claimAt > closeAt, "INVALID CLAIM_AT");

        // IERC20(idoToken).safeTransferFrom(creator, address(this), totalAmountIDO);

        uint256 index = IDOs.length;
        IDO memory ido =
            IDO({
                creator: creator,
                idoToken: idoToken,
                payToken: payToken,
                totalAmountIDO: totalAmountIDO,
                totalAmountPay: totalAmountPay,
                swappedAmountIDO: 0,
                swappedAmountPay: 0,
                totalCommittedAmount: 0,
                minAmountPay: minAmountPay,
                maxAmountPay: maxAmountPay,
                openAt: openAt,
                closeAt: closeAt,
                claimAt: claimAt
            });

        IDOs.push(ido);

        emit CreateIDO(index, msg.sender, ido);
    }

    function increaseCap(uint256 index, uint256 amountIDO, uint256 amountPay) public 
        onlyOwner 
        existIDO(index) {
        IDO storage ido = IDOs[index];
        // require(ido.totalAmountIDO.div(ido.totalAmountPay) == amountIDO.div(amountPay), "WRONG AMOUNT");
        // require(amountIDO % amountPay == 0, "NOT INTEGER RATIO");
        
        // IERC20(ido.idoToken).safeTransferFrom(ido.creator, address(this), amountIDO);
        
        ido.totalAmountIDO = ido.totalAmountIDO.add(amountIDO);
        ido.totalAmountPay = ido.totalAmountPay.add(amountPay);
    }

    function decreaseCap(uint256 index, uint256 amountIDO, uint256 amountPay) public
        onlyOwner
        existIDO(index) {
        IDO storage ido = IDOs[index];
        uint256 n =  numberOfUserCommitted(index);
        // require(ido.totalAmountIDO.div(ido.totalAmountPay) == amountIDO.div(amountPay), "WRONG AMOUNT 1");
        // require(amountIDO % amountPay == 0, "NOT INTEGER RATIO");
        
        require(ido.minAmountPay.mul(n) <= ido.totalAmountPay.sub(amountPay), "WRONG AMOUNT 2");
        require(ido.totalAmountIDO.sub(amountIDO) >= ido.swappedAmountIDO, "WRONG AMOUNT 3");

        // IERC20(ido.idoToken).transfer(ido.creator, amountIDO);

        ido.totalAmountIDO = ido.totalAmountIDO.sub(amountIDO);
        ido.totalAmountPay = ido.totalAmountPay.sub(amountPay);
    }

    function updateInfo(uint index, uint256 minAmountPay, uint256 maxAmountPay, uint256 openAt, uint256 closeAt, uint256 claimAt) public 
        onlyOwner() 
        // existIDO(index)
        // notOpen(index) 
        {
        IDO storage ido = IDOs[index];
        ido.minAmountPay = minAmountPay;
        ido.maxAmountPay = maxAmountPay;
        ido.openAt = openAt;
        ido.closeAt = closeAt;
        ido.claimAt = claimAt;
    }

    function commit(
        uint256 index,
        uint256 amount,
        Proof memory _proof
    ) public payable existIDO(index) isOpening(index) {
        require(amount > 0, "AMOUNT MUST BE GREATER THAN 0");
        require(
            verifyProof(signer, abi.encodePacked(uint(0x1), index, msg.sender, amount), _proof),
            "WRONG PROOF"
        );
        
        IDO storage ido = IDOs[index];

        uint256 n =  numberOfUserCommitted(index);
        uint256 commitedAmount = userCommitedAmount[msg.sender][index];
        uint256 newCommitedAmount = commitedAmount.add(amount);
        require(
            ido.minAmountPay <= newCommitedAmount && newCommitedAmount <= ido.maxAmountPay,
            "WRONG AMOUNT"
        );
        require(
            ido.minAmountPay.mul(n + 1) <= ido.totalAmountPay,
            "CANNOT COMMIT"
        );

        if (ido.payToken == address(0)) {
            require(msg.value == amount, "INVALID MSG.VALUE");
        } else {
            require(msg.value == 0, "MSG.VALUE SHOULD BE ZERO");
            IERC20(ido.payToken).safeTransferFrom(
                msg.sender,
                address(this),
                amount
            );
        }

        // the first commit
        if (commitedAmount == 0) {
            userCommited[index].push(msg.sender); //accept duplicate
        }

        userCommitedAmount[msg.sender][index] = commitedAmount.add(amount);
        ido.totalCommittedAmount = ido.totalCommittedAmount.add(amount);

        emit Commit(index, msg.sender, amount);
    }

    function removeCommitment(
        uint256 index,
        uint256 amount,
        uint256 removeIndex,
        Proof memory _proof
    ) public existIDO(index) {
        require(
            verifyProof(
                signer,
                abi.encodePacked(uint(0x2), index, msg.sender, amount),
                _proof
            ),
            "WRONG PROOF"
        );

        IDO storage ido = IDOs[index];
        uint256 commitedAmount = userCommitedAmount[msg.sender][index];
        require(amount <= commitedAmount, "WRONG AMOUNT");
        require(userCommited[index][removeIndex] == msg.sender, "WRONG REMOVE INDEX");
        
        uint256 newCommitedAmount = commitedAmount.sub(amount);
        require(newCommitedAmount == 0 || newCommitedAmount >= ido.minAmountPay, "NOT GOOD COMMITTED AMOUNT");

        userCommitedAmount[msg.sender][index] = commitedAmount.sub(amount);
        ido.totalCommittedAmount = ido.totalCommittedAmount.sub(amount);

        if (newCommitedAmount == 0) {
            uint256 lastIndex = userCommited[index].length - 1;
            address lastAddress = userCommited[index][lastIndex];
            userCommited[index][removeIndex] = lastAddress;
            userCommited[index].pop();
        }

        transferHelper(ido.payToken, msg.sender, amount);

        emit RemoveCommitment(index, msg.sender, amount);
    }

    function userClaim(
        uint256 index,
        address payable user,
        uint256 payAmount,
        Proof memory _proof
    ) public existIDO(index) canClaim(index) {
        require(address(vesting) != address(0x0), "MISSING vesting contract");        
        require(
            verifyProof(signerClaim, abi.encodePacked(uint(0x3), index, user, payAmount), _proof),
            "WRONG PROOF"
        );
        IDO storage ido = IDOs[index];
        uint256 commitedAmount = userCommitedAmount[user][index];
        require(vesting.idoToken() == ido.idoToken, "LuaSwapIDO: Wrong token in vesting");        
        require(0 < commitedAmount, "NO COMMITED AMOUNT");
        require(payAmount <= commitedAmount, "WRONG PAY AMOUNT");

        uint256 idoAmount = payAmount
            .mul(ido.totalAmountIDO)
            .div(ido.totalAmountPay);
        uint256 returnAmount = commitedAmount.sub(payAmount);
        uint256 _amount0 = ido.totalAmountIDO.sub(ido.swappedAmountIDO);
        require(idoAmount <= _amount0, "PAY AMOUNT TOO BIG");

        userCommitedAmount[user][index] = 0;
        ido.totalCommittedAmount = ido.totalCommittedAmount.sub(commitedAmount);
        
        ido.swappedAmountIDO = ido.swappedAmountIDO.add(idoAmount);
        ido.swappedAmountPay = ido.swappedAmountPay.add(payAmount);
        userSwappedAmountIDO[user][index] = userSwappedAmountIDO[user][index].add(idoAmount);
        userSwappedAmountPay[user][index] = userSwappedAmountPay[user][index].add(payAmount);

        if (returnAmount > 0) {
            transferHelper(ido.payToken, user, returnAmount);
        }

        if (payAmount > 0) {
            transferHelper(ido.payToken, ido.creator, payAmount);
        }

        if (idoAmount > 0) {
            vesting.vestingFor(user, idoAmount);
        }

        emit UserClaim(index, user, idoAmount);
    }
}