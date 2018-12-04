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
        uint depositId;
        uint amount;
        // bytes data;
        bool executed;
    }
    
    mapping (uint => Deposit) private deposits;
    mapping (uint => Transaction) private transactions;
    mapping (address => uint) private userToDeposit;
    mapping (uint => mapping (address => bool)) public confirmations;
    
    uint constant public MAX_OWNER_COUNT = 5;
    uint required;
    uint depositCount;
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
        require(userToDeposit[msg.sender] != 0);
        _;
    }

    // functions

    constructor (address _daiInterfaceAddress)
        public
    {
        required = 1;
        depositCount = 0;
        transactionCount = 0;
        daiContract = ERC20Interface(_daiInterfaceAddress);
    }
    
    function setDaiContractAddress (address _contractAddress) external onlyOwner {
        daiContract = ERC20Interface(_contractAddress);
    }
    
    //@dev sudenidepositsiteruuserniha,sokonidepositsuru.
    function () payable public {
        deposits[depositCount] = Deposit(msg.value, msg.sender);
        userToDeposit[msg.sender] = depositCount;
        depositCount = depositCount.add(1);
    }
    
    function depositDai (uint _amount) public {
        require(daiContract.transfer(address(this), _amount));
    }
    
    function makeTransaction (uint _depositId, uint _amount) private {
        transactions[transactionCount] = Transaction({
            depositId: _depositId,
            amount: _amount,
            //data: _data,
            executed: false
        });
    }
    // @dev msg.sender? owner あとで直す
    function confirmSelling (uint _depositId, uint _amount, address _userAddress) public onlyDepositedUser{
        confirmations[transactionCount][msg.sender] = false;
        confirmations[transactionCount][_userAddress] = false;
        makeTransaction(_depositId, _amount);
        transactionCount = transactionCount.add(1);
    }
}
