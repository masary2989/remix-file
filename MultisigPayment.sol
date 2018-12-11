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
    }
    
    // @dev mappingは全てあとでprivateへ変更
    mapping (address => Deposit) public deposits;
    mapping (uint => Transaction) public transactions;
    mapping (address => uint[]) public userToTransactions;
    mapping (uint => mapping (address => bool)) public confirmations;
    
    uint constant public MAX_OWNER_COUNT = 5;
    uint required;
    uint transactionCount;
    
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
    modifier validBalance() {
        uint usedAmount;
        if (userToTransactions[msg.sender].length > 0) {
            uint[] storage transactionIds = userToTransactions[msg.sender];
            for (uint i=0; i<transactionIds.length; i.add(1)) {
                if (transactions[transactionIds[i]].executed
                    && transactions[transactionIds[i]].confirmed) {
                    usedAmount.add(transactions[transactionIds[i]].amount);
                } else if (!transactions[transactionIds[i]].executed) {
                    usedAmount.add(transactions[transactionIds[i]].amount);
                }
            
            }
            require(deposits[msg.sender].depositAmount.sub(usedAmount) > 0);
        }
        _;
    }

    // functions

    constructor (address _daiInterfaceAddress)
        public
    {
        required = 1;
        transactionCount = 0;
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
    function _makeTransaction (uint _amount) internal returns (bool success) {
        userToTransactions[msg.sender].push(transactionCount);
        transactions[transactionCount] = Transaction({
            amount: _amount,
            confirmed: false,
            executed: false
        });
        return (true);
    }
    // @dev 一個目のconfirmはmsg.sender? owner あとで直す
    function confirmSelling (uint _depositId, uint _amount, address _userAddress) public onlyOwner validBalance {
        confirmations[transactionCount][owner()] = true;
        confirmations[transactionCount][_userAddress] = false;
        require(_makeTransaction(_amount));
        transactionCount = transactionCount.add(1);
    }
    
    function userDeposit () public view returns (uint, address) {
        uint depositAmount = deposits[msg.sender].depositAmount;
        address userAddress = deposits[msg.sender].userAddress;
        return (depositAmount, userAddress);
    }
    
    function userTransactions () public view returns (uint[]) {
        return (userToTransactions[msg.sender]);
    }
    
    function userTransaction (uint _transactionId) public view returns (uint, bool, bool) {
        uint amount = transactions[_transactionId].amount;
        bool confirmed = transactions[_transactionId].confirmed;
        bool executed = transactions[_transactionId].executed;
        return (amount, confirmed, executed);
    } 
}
