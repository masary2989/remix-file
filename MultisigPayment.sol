pragma solidity ^0.4.24;


import "github.com/masary2989/zepfile/Ownable.sol";
import "github.com/masary2989/zepfile/SafeMath.sol";
import "./daiInterface.sol";


contract MultisigPayment is Ownable{
    using SafeMath for uint;
    
    // event
    
    event ChangeDaiAddress(address daiAddress);
    event DepositEvent(address indexed sender, uint value);
    event OwnerConfirmation(address indexed sender, uint indexed transactionId);
    event UserConfirmation(address indexed sender, uint indexed transactionId);
    event UserExit(address indexed sender, uint value);
    event OwnerWithdrawal(address indexed sender, uint value);
    
    
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
    
    // mapping
    mapping (address => Deposit) private deposits;
    mapping (uint => Transaction) private transactions;
    mapping (address => uint[]) private userToTransactions;
    mapping (uint => mapping (address => bool)) public confirmations;
    
    uint constant public MAX_OWNER_COUNT = 5;
    uint required;
    uint transactionCount;
    uint public ownerBalance;
    
    // modifiers
    
    modifier onlyWallet() {
         require(msg.sender != address(this));
        _;
    }
    
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
    // @dev User balance validation
    modifier validBalance(address _userAddress, uint _price) {
        require(deposits[_userAddress].depositAmount.sub(_price) > 0);
        _;
    }
    // @dev checking own transaction or not
    modifier checkOwnTransaction (uint _transactionId) {
        require(transactions[_transactionId].userAddress == msg.sender);
        _;
    }
    
    modifier isExecutedLastTX(address _userAddress) {
        require(transactions[userToTransactions[_userAddress][userToTransactions[_userAddress].length-1]].executed);
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
        emit ChangeDaiAddress(_contractAddress);
    }
    
    // deposit dai to this contract
    function depositDai (uint _amount) public {
        require(daiContract.transferFrom(msg.sender, address(this), _amount));
        if (deposits[msg.sender].userAddress == 0x0) {
            deposits[msg.sender] = Deposit(_amount, msg.sender);
        } else {
            deposits[msg.sender].depositAmount = deposits[msg.sender].depositAmount.add(_amount);
        }
        emit DepositEvent(msg.sender, _amount);
    }
    
    //@dev making transaction struct
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
    // @dev owner confirming selling item
    function confirmSelling (uint _amount, address _userAddress) public onlyOwner validBalance(_userAddress, _amount) isExecutedLastTX(_userAddress) {
        confirmations[transactionCount][owner()] = true;
        confirmations[transactionCount][_userAddress] = false;
        require(_makeTransaction(_amount, _userAddress));
        deposits[_userAddress].depositAmount = deposits[_userAddress].depositAmount.sub(_amount);
        emit OwnerConfirmation(msg.sender, transactionCount);
        transactionCount = transactionCount.add(1);
    }
    // @dev user confirming paying to item
    function confirmPaying (uint _transactionId) public onlyDepositedUser checkOwnTransaction(_transactionId) {
        confirmations[_transactionId][msg.sender] = true;
        ownerBalance = ownerBalance.add(transactions[_transactionId].amount);
        transactions[_transactionId].executed = true;
        transactions[_transactionId].confirmed = true;
        emit OwnerConfirmation(msg.sender, _transactionId);
    }
    
    function discardTX (uint _transactionId, address _userAddress) public onlyOwner {
        require(transactions[_transactionId].userAddress == _userAddress);
        transactions[_transactionId].confirmed = false;
        deposits[_userAddress].depositAmount = deposits[_userAddress].depositAmount.add(transactions[_transactionId].amount);
        transactions[_transactionId].executed = true;
    }
    
    // @dev exit user deposit dai
    function exit (uint amount) public onlyDepositedUser {
        deposits[msg.sender].depositAmount = deposits[msg.sender].depositAmount.sub(amount);
        require(daiContract.transfer(msg.sender, amount));
        emit UserExit(msg.sender, amount);
    }
    
    // @dev withdrawaling owner profit
    function profitWithdrawal (uint amount) public onlyOwner {
        ownerBalance = ownerBalance.sub(amount);
        require(daiContract.transfer(owner(), amount));
        emit UserExit(msg.sender, amount);
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
