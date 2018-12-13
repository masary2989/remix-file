pragma solidity ^0.4.24;

import "github.com/OpenZeppelin/openzeppelin-solidity/contracts/ownership/Ownable.sol";
import "github.com/OpenZeppelin/openzeppelin-solidity/contracts/math/SafeMath.sol";
import "./daiInterface.sol";

// Goxしないようにちゃんとコントラクトアドレスから動かせるようにしよう
contract MultisigPayment is Ownable{
    using SafeMath for uint;
    // valiables
    
    ERC20Interface daiContract;
    
    struct Deposit {
        uint depositAmount;
        address userAddress;
    }
    
    struct Transaction {
        uint amount;
        bool confirmed;
        bool executed;
        address userAddress;
    }
    
    // @dev mappingは全てあとでprivateへ変更
    mapping (address => Deposit) public deposits;
    mapping (uint => Transaction) public transactions;
    mapping (address => uint[]) public userToTransactions;
    mapping (uint => mapping (address => bool)) public confirmations;
    
    uint constant public MAX_OWNER_COUNT = 5;
    uint required;
    uint transactionCount;
    uint public ownerBalance;
    
    // modifiers
    
    modifier validRequirement(uint _ownerCount, uint _required) {
        if (_ownerCount > MAX_OWNER_COUNT
            || _required > _ownerCount
            || _required == 0
            || _ownerCount == 0)
            revert();
        _;
    }
    
    modifier onlyDepositedUser() {
        require(deposits[msg.sender].depositAmount != 0);
        _;
    }
    // @dev 今支払う額も入れる
    // @dev msg.senderじゃなくて、送り先（これのmsg.senderはownerになる）
    modifier validBalance(address _userAddress, uint _price) {
        require(deposits[_userAddress].depositAmount.sub(_price) > 0);
        _;
    }
    
    modifier checkOwnTransaction (uint _transactionId) {
        require(transactions[_transactionId].userAddress == msg.sender);
        _;
    }

    // functions

    constructor (address _daiInterfaceAddress)
        public
    {
        required = 1;
        transactionCount = 0;
        ownerBalance = 0;
        daiContract = ERC20Interface(_daiInterfaceAddress);
        
    }
    
    function setDaiContractAddress (address _contractAddress) external onlyOwner {
        daiContract = ERC20Interface(_contractAddress);
    }
    
    //@dev sudenidepositsiteruuserniha,sokonidepositsuru.
    function () payable public {
        deposits[msg.sender] = Deposit(msg.value, msg.sender);
    }
    
    function depositDai (uint _amount) public {
        require(daiContract.transferFrom(msg.sender, address(this), _amount));
        deposits[msg.sender] = Deposit(_amount, msg.sender);
    }
    
    //@dev これのmsg.senderはownerになる
    function _makeTransaction (uint _amount, address _userAddress) internal returns (bool success) {
        userToTransactions[_userAddress].push(transactionCount);
        transactions[transactionCount] = Transaction({
            amount: _amount,
            confirmed: false,
            executed: false,
            userAddress: _userAddress
        });
        return (true);
    }
    // @dev ownerが実行
    function confirmSelling (uint _amount, address _userAddress) public onlyOwner validBalance(_userAddress, _amount) {
    // function confirmSelling (uint _amount, address _userAddress) public onlyOwner {
        confirmations[transactionCount][owner()] = true;
        confirmations[transactionCount][_userAddress] = false;
        require(_makeTransaction(_amount, _userAddress));
        deposits[_userAddress].depositAmount = deposits[_userAddress].depositAmount.sub(_amount);
        ownerBalance = ownerBalance.add(_amount);
        transactionCount = transactionCount.add(1);
    }
    // @dev ユーザーが実行
    function confirmPaying (uint _transactionId) public onlyDepositedUser checkOwnTransaction(_transactionId) {
        confirmations[_transactionId][msg.sender] = true;
        transactions[_transactionId].executed = true;
        transactions[_transactionId].confirmed = true;
    }
    
    // @dev ユーザーが実行
    function exit (uint amount) public onlyDepositedUser {
        deposits[msg.sender].depositAmount = deposits[msg.sender].depositAmount.sub(amount);
        require(daiContract.transfer(msg.sender, amount));
    }
    
    // @dev オーナーが実行
    function profitWithdrawal (uint amount) public onlyOwner {
        ownerBalance = ownerBalance.sub(amount);
        require(daiContract.transfer(owner(), amount));
    }
    
    function userDeposit () public view returns (uint, address) {
        uint depositAmount = deposits[msg.sender].depositAmount;
        address userAddress = deposits[msg.sender].userAddress;
        return (depositAmount, userAddress);
    }
    
    function userTransactions () public view returns (uint[]) {
        return (userToTransactions[msg.sender]);
    }
    
    function userTransaction (uint _transactionId) public view returns (uint, bool, bool, address) {
        uint amount = transactions[_transactionId].amount;
        bool confirmed = transactions[_transactionId].confirmed;
        bool executed = transactions[_transactionId].executed;
        address userAddress = transactions[_transactionId].userAddress;
        return (amount, confirmed, executed, userAddress);
    } 
}
