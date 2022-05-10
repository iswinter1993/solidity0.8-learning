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
    //immutable 部署时定义的常量,节省gas
    address public immutable owner;


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
        //内存中定义结构体,内存中不能修改删除
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
    //动态部署无参数合约
    function getHelloWorldCode() external pure returns(bytes memory){
        bytes memory bytecode = type(HelloWorld).creationCode;//获取HelloWorld合约的编译后code
        return bytecode;
    }
    //动态部署 constructor 有参数 合约
    function getCounterCode(uint _x) external pure returns(bytes memory){
        bytes memory bytecode = type(Counter).creationCode;
        //把合约编译后的code 和 encode后的参数 进行打包后返回
        return abi.encodePacked(bytecode, abi.encode(_x));
    }
    //abi.encodeWithSignature 调用合约中的方法 
    function getcalldata(uint _owner) external pure returns(bytes memory){
        //获得 abi.encodeWithSignature 打包后的调用合约中的方法的code 16进制编码 ，如执行add的code
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

//给继承的合约传参数
contract S {
    string public name;
    constructor(string memory _name){
        name = _name;
    }
    function getname() public returns(string memory){
        return name;
    }
}

contract T {
    string public text;
    constructor(string memory _text){
        text = _text;
    }
}
//继承后给父级构造函数传参数
contract U is S , T('s'){//直接给T合约传参
    //由部署者输入参数
    string public a;
    constructor(string memory _name) S(_name) {
        //调用父级函数
        a = S.getname();
    }
}


//支付相关
contract Payable {
    address payable public owner;
    constructor(){
        //msg.sender默认是没有 payable 的属性的，所以要包裹一下
        owner = payable(msg.sender);
    }
    //回退函数,调用不存在的函数 或者 发送主币失败 会走这个fallback。
    fallback() external payable{}

    //发送主币
    function deposit() external payable {

    }

    function getBalance() external view returns(uint) {
        return address(this).balance;
    }
}

//发送主币
// transfer - 2300 gas
// call - 2300 gas return bool
// send - all gas return (success,data)
contract SendEth {
    constructor() payable {}
    fallback() external payable {}

    function sendByTransfer(address payable _to) external payable {
        //携带gas 
        _to.transfer(123);
    }

    function sendBySend(address payable _to) external payable {
        _to.send(123);
    }

    function sendByCall(address payable _to) external payable {
        (bool success, ) = _to.call{value:123}("");
    }
}
//相当于一个钱包
contract GetEth {
    event Log(uint amount, uint gas);
    receive() external payable {
        emit Log(msg.value, gasleft());
    }
}

