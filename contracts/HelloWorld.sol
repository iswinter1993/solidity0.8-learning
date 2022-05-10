// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

contract HelloWorld {
    address public owner = msg.sender;
    bool public B;
    uint public number;
    bytes32 b32;
    // 设置合约owner
    function setOwner(address _owner) public {
        require(msg.sender == owner,'no owner');
        owner = _owner;

    }

    function add (uint a) public {
        uint x = 1;
        uint y = 1;
        number = x + y + a;
    } 

    function sub () public {
        uint x = 1;
        uint y = 1;
        number = x - y;
    }
    //pure 没有读取全局变量时使用。view 读取到全局变量时使用
    function getNumber () external view returns(uint, bool){
        return (number, true);
    }
    //隐式返回
    function getNumberYinshi () external view returns(uint x, bool b){
        x = number;
        b = true;
    }
}

//计数器合约

error isFalse(address caller);

contract Counter {
    uint public count;
    //constant 定义常量
    uint public constant A = 124; 
    bool public paused;
    address public owner;


    //映射
    mapping(address => uint) public balance;
    //嵌套映射 
    mapping(address => mapping(address => bool)) public isFriend;
    function mappingExample() external {
        balance[msg.sender] = 123;
        isFriend[msg.sender][address(this)] = true;
    }
    
    //结构体
    struct Car {
        string color;
        uint price;
        address owner;
    }
    Car public car;
    Car[] public cars;
    mapping(address => Car[]) public ownerCars;
    function example() external view {
        //内存中定义结构体
        Car memory toyota = Car('red',123,msg.sender);
    }

    //Enum枚举
    enum States {
        None,
        Pending,
        Finish
    }
    States public states;
    function getEnum() external view returns(States){
        return states;
    }
    //枚举类型 通过索引赋值 
    function setEnum( States _states ) external {
        states = _states;
    }
    //数组
    uint[] public arr;
    //固定长度数组
    uint[3] public arr1;
    function arrExmple() external pure{
        //内存中创建数组,此数组只能定义固定长度数组
        uint[] memory arr = new uint[](5);
    }

    constructor(uint x){
        owner = msg.sender;
    }


    //修饰符
    modifier whenNotPaused () {
        require(!paused, 'is paused');
        _;
    }
    //带参数修饰符
    modifier cap(uint x) {
        require( x < 100, 'x >= 100' );
        _;
    }
    function setPaused() external {
        paused = !paused;
    }
    function inc (uint x) external whenNotPaused cap(x) {
        count ++ ;
        if(count > 10) {
            count -- ;

            revert isFalse(msg.sender); 
        }
    }
    function dec () external whenNotPaused{
        count -- ;
    }
}


//通过合约 部署 合约
contract Proxy {
    event Deploy(address);
    
    
    //abi.encodeWithSignature 调用合约中的方法 
    function getcalldata(uint _owner) external pure returns(bytes memory){
        //获得 abi.encodeWithSignature 打包后的调用合约中的方法的code 16进制编码 ，如执行setOwner的code
        return abi.encodeWithSignature('setOwner(address)', _owner);
    }
    //执行操作, _target 要执行的合约地址，_data 此合约地址中abi.encodeWithSignature打包后的code
    function execute(address _target, bytes memory _data) external payable {
        (bool success, ) = _target.call{value: msg.value}(_data);
        require(success,'failed');
    }
    function getBytes32(uint salt) external pure returns (bytes32){
        return bytes32(salt);
    }
    function deploy(bytes32 salt) external payable {
        HelloWorld h = new HelloWorld{salt:salt}();
        address addr = address(h);
        emit Deploy(addr);
    }
}