/********************************************************************
 * This is a generic proxy contract that is also an ERC20, so it can
 *   be used to sell/buy an identity in decentralized markets like 
 *   etherdelta.
 *
 * Adria Massanet <adria@codecontext.io>
 ********************************************************************/

/* CAUTION : EXPERIMENTAL STUFF */
/*           NOT REALLY TESTED  */

pragma solidity ^0.4.18;

contract ProxyToken {

  event Approval(address indexed owner, address indexed spender, uint256 value);
  event Transfer(address indexed from, address indexed to, uint256 value);

  address internal lib;
  address public owner;
  mapping (address => mapping (address => uint256)) internal allowed;
  
  function ProxyToken() public {
      owner = msg.sender;
  }
  
  function __constructor(address _addr) public {
      assert (owner==0);
      owner = _addr;
  }   
    
  function decimals() public pure returns (uint8) {
    return 0;    
  }

  function symbol() view public returns (string) {
    uint value = uint(this);
    bytes3 prefix = 0x50424B;
    bytes16 hexchars = 0x30313233343536373839616263646566;
    bytes memory b = new bytes(prefix.length+8);
    for (uint i=0;i<prefix.length;i++) {
        b[i]=prefix[i];
    }
    for (uint j=prefix.length;j<b.length;j++) {
        b[j]=hexchars[value % 16];
        value = value / 16;            
    }
    return string(b);
  }

  function name() view public returns (string) {
    return symbol();
  }

  function totalSupply() public pure returns (uint256) {
    return 1;
  }
  
  function balanceOf(address _who) public view returns (uint256) {
      if (_who == owner) {
          return 1;
      } else {
          return 0;
      }
  }
  
  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= 1);
    if (_value == 1 ) {
      require(msg.sender == owner);
      owner = _to;
    }
    Transfer(msg.sender,_to,_value);
  }
  
  function allowance(address _owner, address _spender) public view returns (uint256) {
     return allowed[_owner][_spender];
  }
  
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));

    if (_value == 1) {
        require(allowed[_from][msg.sender]==1);
        require(_from == owner);
        owner = _to;
        allowed[_from][msg.sender]=0;
    }

    Transfer(_from, _to, _value);
    return true;      
  }
  
  function approve(address _spender, uint256 _value) public returns (bool) {
    require(_value <= 1);

    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
    return true;      
  }
  
  // top up contract
  function () public payable {
  }
  
  // execute function
  function execute(address _dst, bytes _calldata, uint256 _value ) public {
    require(msg.sender == owner);
    
    assembly {

        let result := call(sub(gas, 10000), _dst, _value, add(_calldata, 0x20), mload(_calldata), 0, 0)
        let size := returndatasize

        let ptr := mload(0x40)
        returndatacopy(ptr, 0, size)

        switch result case 0 { revert(ptr, size) }
        default { return(ptr, size) }
    }
  }
  
  // create contract
  function create(bytes _code, uint256 _value) public {
    require(msg.sender == owner);
    
    address addr;

    assembly {
        addr := create(callvalue, add(_code, 0x20), mload(_code))
        if iszero(extcodesize(addr)) { revert(0, 0) }
        return(addr, 20)
    }

  }
  
}

contract ProxyTokenForwader {
    address lib;
    
    function ProxyTokenForwader(address _lib, address _owner) public {
        lib = _lib;

        // prepare the call data, 4 for signature + 32 for the address
        bytes memory msgdata = new bytes(36);
        bytes4 sig = bytes4(keccak256("__constructor(address)"));
        assembly {
            mstore(add(msgdata,32),sig)
            mstore(add(msgdata,36), _owner)
        }

        // call __constructor(_owner)
        forward(lib, msgdata, false);
    }
    
    function () payable public {
        forward(lib,msg.data,true);
    }
    
    function forward(address _dst, bytes _calldata, bool _ret) internal {
        
        assembly {
            let result := delegatecall(sub(gas, 10000), _dst, add(_calldata, 0x20), mload(_calldata), 0, 0)
            let size := returndatasize

            let ptr := mload(0x40)
            returndatacopy(ptr, 0, size)

            // revert instead of invalid() bc if the underlying call failed with invalid() it already wasted gas.
            // if the call returned error data, forward it
            switch result
            case 0  { revert(ptr, size) }
            default { if eq(_ret, 1) { return(ptr, size) } }
        }
    }
    
}

contract ProxyTokenFactory {
    ProxyToken public lib;
    
    function ProxyTokenFactory() public {
        lib = new ProxyToken();
    }
    
    function create() external returns (ProxyToken) {
        address created = new ProxyTokenForwader(lib,msg.sender);
        return ProxyToken(created);
    }
}
