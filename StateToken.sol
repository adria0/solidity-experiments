pragma solidity ^0.4.15;

library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
    return c;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

contract StandardTokenWithState  {

  uint public state;

  using SafeMath for uint;
  uint256 public totalSupply;
  
  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);
  
  mapping (address => mapping (address => uint256)) internal allowed;
  mapping (address => uint256) balances;

  function StandardTokenWithState() public{
    state = 0;
  }

  function setBalance(address _addr, uint _value) internal {

    if (balances[_addr] > 0) {
        state ^= uint(keccak256(uint(1),_addr,balances[_addr]));
    }
    
    if (_value > 0 ) {
        state ^= uint(keccak256(uint(1),_addr,_value));
    }
    
    balances[_addr] = _value;
   
  }

  function setAllowed(address _from, address _to, uint _value) internal {

    if (allowed[_from][_to] > 0) {
        state ^= uint(keccak256(uint(2),_from,_to,allowed[_from][_to]));
    }
    
    if (_value > 0 ) {
        state ^= uint(keccak256(uint(2),_from,_to,_value));
    }
    
    allowed[_from][_to] = _value;
   
  }

  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[msg.sender]);
    
    if (_value > 0) {
        setBalance(msg.sender,balances[msg.sender].sub(_value));
        setBalance(msg.sender,balances[_to].add(_value));
    }
    
    Transfer(msg.sender, _to, _value);
    return true;
  }

  function balanceOf(address _owner) public constant returns (uint256 balance) {
    return balances[_owner];
  }

  function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[_from]);
    require(_value <= allowed[_from][msg.sender]);

    if (_value > 0) {
        setBalance(msg.sender,balances[_from].sub(_value));
        setBalance(msg.sender,balances[_to].add(_value));
        setAllowed(_from,msg.sender,allowed[_from][msg.sender].sub(_value));
    }
    
    Transfer(_from, _to, _value);
    return true;
  }

  function approve(address _spender, uint256 _value) public returns (bool) {

    if (allowed[msg.sender][_spender] != _value) {
        setAllowed(msg.sender,_spender,_value);
    }
    
    Approval(msg.sender, _spender, _value);
    return true;
  }

  function allowance(address _owner, address _spender) public constant returns (uint256 remaining) {
    return allowed[_owner][_spender];
  }

}
