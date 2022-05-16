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

//1.计数器合约

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


//2.通过合约 部署 合约
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
    //abi.encodeWithSignature 打包合约中的方法 
    function getcalldata(uint _owner) external pure returns(bytes memory){
        //获得 abi.encodeWithSignature 打包后的合约中的方法的code 16进制编码 ，如执行add的code
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

//3.给继承的合约传参数
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
//3.继承后给父级构造函数传参数
contract U is S , T('s'){//直接给T合约传参
    //由部署者输入参数
    string public a;
    constructor(string memory _name) S(_name) {
        //调用父级函数
        a = S.getname();
    }
}


//4.支付相关
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

//5.发送主币
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
//5.相当于一个钱包
contract GetEth {
    event Log(uint amount, uint gas);
    receive() external payable {
        emit Log(msg.value, gasleft());
    }
}


//6.委托调用改变合约的值
contract TestDelegateCall { //被调用合约
// 定义的变量 要和 委托合约的变量一致
    uint public num;
    address sender;

    function setVars(uint _num) external payable {
        num = _num;
        sender = msg.sender;
    }
}
//6.委托调用
contract DelegateCall { //委托合约
// 定义的变量 要和 委托合约的变量一致
    uint public num;
    address public sender;
    //_target 要调用合约的地址
    function setVars(address _target, uint _num) external payable {
        //委托调用 方法1.
        (bool success, ) = _target.delegatecall(abi.encodeWithSignature('setVars(uint)', _num));
        //委托调用 方法2.
        // (bool success, ) = _target.delegatecall(abi.encodeWithSelector(Test.setVars.selector,_num));
        require(success,'delegatecall failed');

    }

}


//7.对一个消息进行签名，验证
contract VerifySign {
    /*
        @_signer 签名人地址
        @_message 要签名的地址
        @_sig 签名后的结果
    **/
    // 验证
    function verify(address _signer ,string memory _message, bytes memory _sig) external pure returns(bool) {
       bytes32 messageHash = getMessageHash(_message);//获取消息Hash
       bytes32 ethSignMessageHash = getethSignMessageHash(messageHash); //对messageHash再进行一次hash运算
        // recover 函数恢复 hash值 ，比较_signer是否相等
       return recover(ethSignMessageHash, _sig) == _signer;

    }
    function getMessageHash(string memory _message) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(_message));
    }

    function getethSignMessageHash(bytes32 _messageHash) public pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32",_messageHash));
    }

    function recover(bytes32 _ethSignMessageHash, bytes memory _sig) public pure returns (address) {
        (bytes32 r, bytes32 s, uint8 v) = _split(_sig);
        //ecrecover 还原的方法
        return ecrecover(_ethSignMessageHash,v, r ,s);
    }

    //_split拼接_sig
    //r - 32位
    //s - 32位
    //v - 1位
    function _split(bytes memory _sig) internal pure returns(bytes32 r, bytes32 s, uint8 v) {
        // 判断_sig长度是否 等于 32 + 32 + 1
        require(_sig.length == 65,"_sig error");
        //内联汇编
        assembly {
            //mload方法在内存中跳过32位 ，add方法 在32位后 插入 _sig值的32位
            r := mload(add(_sig,32))
            s := mload(add(_sig,64))
            //因为uint8只占一位 所以用byte（0，...)来获取一位数
            v := byte(0, mload(add(_sig,96)))
        }
    }   
}

//8.multi call 将多个对合约的请求，打包成一个发送给合约
contract TestMulticall {
    function func1() external view returns(uint,uint) {
        return (1, block.timestamp);
    }

    function func2() external view returns(uint, uint) {
        return (2, block.timestamp);
    }
    //func1 func2获取multicall 中 data 参数的方法
    function getdata1 () public pure returns(bytes memory) {
        //
        return abi.encodeWithSignature('func1');
    }
    function getdata2 () public pure returns(bytes memory)  {
        return abi.encodeWithSignature('func2');
    }
}
//主要利用for循环 和 staticcall 
contract Multicall {
    //targets 两次调用的合约地址，data 两次调用的方法打包后的数据（abi.encodeWithSignature(signatureString, arg);）
    function multicall(address[] memory targets, bytes[] calldata data) external view  returns(bytes[] memory){
        require(targets.length == data.length,"target length == data length");
        //返回的bytes 和 输入的 data 长度相等
        bytes[] memory result = new bytes[](data.length);  

        for(uint i=0; i<targets.length; i++){
            //staticcall静态调用，不会写入数据
            (bool success, bytes memory res) = targets[i].staticcall(data[i]);
            require(success,"call failed");
            result[i] = res;
        }

        return result;
    }
}