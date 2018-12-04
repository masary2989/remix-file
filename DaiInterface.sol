pragma solidity ^0.4.24;
// ----------------------------------------------------------------------------
// ERC Token Standard #20 Interface
// https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20-token-standard.md
// ----------------------------------------------------------------------------
contract ERC20Interface {
    function totalSupply() public constant returns (uint);
    function balanceOf(address tokenOwner) public constant returns (uint balance);
    function allowance(address tokenOwner, address spender) public constant returns (uint remaining);
    function transfer(address to, uint tokens) public returns (bool success);
    function approve(address spender, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}



contract MyContract {
    mapping (address => uint) public depositValue;
 
    address DaiInterfaceAddress = 0xC4375B7De8af5a38a93548eb8453a498222C4fF2; 
    // ここは、イーサリアム上のFavoriteNumberコントラクトのアドレスが入る。
    ERC20Interface daiContract = ERC20Interface(DaiInterfaceAddress);
    // `numberContract`は他のコントラクトを指し示すものになっているぞ 

    function daiBalanceof() public {
      // コントラクトから`getNum`を呼び出せるぞ：
      uint balance = daiContract.balanceOf(msg.sender);
      // ...よし、`num`を操作するぞ。
      depositValue[msg.sender] = balance;
    }
    
    function daiTransfer() public {
      // コントラクトから`getNum`を呼び出せるぞ：
      uint balance = daiContract.balanceOf(msg.sender);
      // ...よし、`num`を操作するぞ。
      depositValue[msg.sender] = balance;
    }
}
