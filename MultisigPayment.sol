pragma solidity ^0.4.24;

import "github.com/OpenZeppelin/openzeppelin-solidity/contracts/ownership/Ownable.sol";


contract MultisigPayment is Ownable{
    
    // valiables
    
    struct Deposit {
        uint depositAmount;
        address userAddress;
    }
    
    mapping (uint => Deposit) private depositDetails;
    mapping (address => uint) private userToDeposit;
    
    uint constant public MAX_OWNER_COUNT = 5;
    uint required = 1;
    uint depositCount = 0;
    
    // modifiers
    
    modifier validRequirement(uint ownerCount, uint _required) {
        if (ownerCount > MAX_OWNER_COUNT
            || _required > ownerCount
            || _required == 0
            || ownerCount == 0)
            revert();
        _;
    }
    
    modifier onlyDepositedUser() {
        require(userToDeposit[msg.sender] != 0);
        _;
    }

    // functions

    //constructor (address _owner)
        //public
    //{
        //owner = _owner;
    //}
    
    //@dev sudenidepositsiteruuserniha,sokonidepositsuru.
    function () payable public {
        depositDetails[depositCount] = Deposit(msg.value, msg.sender);
        userToDeposit[msg.sender] = depositCount;
        depositCount++;
    }
    
    function spend (address toAddress) public onlyDepositedUser {
        
    }
    
}
