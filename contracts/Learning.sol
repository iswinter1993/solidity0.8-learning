// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;


contract C {
    uint private data;

    function f(uint a) private pure returns(uint b) { return a + 1; }
    function setData(uint a) public { data = a; }
    function getData() public view returns(uint) { return data; }
    function compute(uint a, uint b) internal pure returns (uint) { return a + b; }
}


contract Learning {
  address public owner = msg.sender;
  uint public last_completed_migration;
  
  modifier restricted() {
    require(
      msg.sender == owner,
      "This function is restricted to the contract's owner"
    );
    _;
  }

  // 自定义错误
  error Unauthorized(address caller);

  //safe math
  function test_Safe_math() public view returns(uint){
    if(msg.sender != owner)
      // revert('aaaaa');
      //使用自定义错误
      revert Unauthorized(msg.sender);
    //0.8自带安全数学计算,会报错
    uint x = 0;
    x--;
    return x;
  }
  function test_unSafe_math() public pure returns(uint){
    uint x = 0;
    //unchecked表示不使用安全数学，会返回uint256最大值溢出
    unchecked {
      x--;
    }
    return x;
  }



  //0.8支持creat2语法
  address public deployedAddress;
  function getBytes32(uint salt) external pure returns (bytes32) {
    return bytes32(salt);
  }
  function createNewContract(bytes32 salt) public {
    C c = new C{salt: salt}();
    address addr = address(c);
    deployedAddress = addr;
  }
  function getdeployedAddress() public view returns (address addrr){
    return deployedAddress;
  }
}
