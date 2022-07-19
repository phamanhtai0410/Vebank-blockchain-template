// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";


contract AccessControl {
    using SafeERC20 for IERC20;

    address payable public owner;

    event SetOperator(address indexed add, bool value);

    constructor(address _ownerAddress) public {
        owner = payable(_ownerAddress);
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function setOwner(address payable _newOwner) external onlyOwner {
        require(_newOwner != address(0));
        owner = _newOwner;
    }

    function emergencyWithdraw(address _token, address payable _to, uint256 amount) external onlyOwner {
        if (_token == address(0x0)) {
            amount = amount != 0 ? amount : address(this).balance;
            payable(_to).transfer(amount);
        }
        else {
            amount = amount != 0 ? amount : IERC20(_token).balanceOf(address(this));
            IERC20(_token).safeTransfer(_to, amount);
        }
    }
}


contract LuaVesting is AccessControl {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    address public IDOContract;

    struct UserInfo {
        uint256 amount;
        uint256 claimedAmount;
        uint256 claimAtsTime;
    }

    mapping(address => UserInfo) public info;
    address public idoToken;
    address[] public users;

    uint256[] public claimPercents;     //[20, 40, 40]
    uint256[] public claimAts;          //[A, B, C]

    constructor(address _owner, uint256[] memory _claimPercent, uint256[] memory _claimAts, address _idoToken) public AccessControl(_owner) {
        require(_claimAts.length == _claimPercent.length, "LuaVesting: Wrong data");
        uint s = 0;
        for (uint i = 0; i < _claimPercent.length; i++) {
            s += _claimPercent[i];
        }
        require(s == 100, "LuaVesting: Wrong percent");
        require(_claimAts[0] > 0, "LuaVesting: Wrong _claimAts[0]"); // TGE
        claimPercents = _claimPercent;
        claimAts = _claimAts;
        idoToken = _idoToken;
    }

    modifier onlyIDO() {
        require(msg.sender == IDOContract);
        _;
    }    

    function getVestingLength() public view returns (uint256) {
        return claimAts.length;
    }

    function setIDO(address _newIDO) external onlyOwner {
        require(_newIDO != address(0));
        IDOContract = _newIDO;
    }

    function _estimateClaim(address user, uint blockTime) private view returns (uint256 amount, uint256 claimAt) {
        amount = 0;
        UserInfo memory ui = info[user];

        claimAt = ui.claimAtsTime;

        for (uint i = 0; i < claimAts.length; i++) {
            uint b = claimAts[i];
            uint p = claimPercents[i];

            if (ui.claimAtsTime < b && b < blockTime) {
                if (i <= claimAts.length - 2) {
                    amount += ui.amount.mul(p).div(100);
                }
                else {
                    amount = ui.amount.sub(ui.claimedAmount);
                }
                claimAt = b;
            }
        }

        if (ui.claimedAmount.add(amount) > ui.amount) {
            amount = ui.amount.sub(ui.claimedAmount);
        }
    }

    function _claim(address user) private {
        UserInfo storage ui = info[user];
        require(ui.amount > 0, "LuaVesting: Wrong data");
        (uint amount, uint claimAt) = _estimateClaim(user, block.timestamp);

        ui.claimedAmount = ui.claimedAmount.add(amount);
        ui.claimAtsTime = claimAt;

        IERC20(idoToken).transfer(user, amount);
    }

    function vestingFor(address add, uint userAmount) public onlyIDO {
        UserInfo storage ui = info[add];
        if (ui.amount == 0) {
            users.push(add);
        }
        ui.amount = ui.amount.add(userAmount);
        _claim(add);
    }

    function claim() public {
        _claim(msg.sender);
    }

    function estimateClaim(address user, uint blockTime) public view returns (uint256 amount) {
        (amount, ) = _estimateClaim(user, blockTime);
    }

    function updateVesting(uint256[] memory _claimPercent, uint256[] memory _claimAts) public onlyOwner {
        require(_claimAts.length == _claimPercent.length, "LuaVesting: Wrong data");
        uint s = 0;
        for (uint i = 0; i < _claimPercent.length; i++) {
            s += _claimPercent[i];
        }
        require(s == 100, "LuaVesting: Wrong percent");
        require(_claimAts[0] > 0, "LuaVesting: Wrong _claimAts[0]"); // TGE
        claimPercents = _claimPercent;
        claimAts = _claimAts;
    }
}

// File: contracts/contracts-v2/LuaSwapIDO.sol

pragma solidity 0.6.12;



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

    function getChainID() private pure returns (uint256) {
        uint256 id;
        assembly {
            id := chainid()
        }
        return id;
    }

    function verifyProof(address _signer, bytes memory _encode, Proof memory _proof) private view returns (bool) {
        if (_signer == address(0x0)) {
            return true;
        }
        bytes32 digest = keccak256(abi.encodePacked(getChainID(), address(this), _proof.deadline, _encode));
        address signatory = ecrecover(digest, _proof.v, _proof.r, _proof.s);
        return signatory == _signer && _proof.deadline >= block.timestamp;
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
        existIDO(index)
        notOpen(index) {
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