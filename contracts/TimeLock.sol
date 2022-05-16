// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;
//时间锁合约
//类似js的栈
//用户操作 后 会推入时间锁，延迟执行
contract TimeLock {
    error NotOwner();
    error Timeerror(uint blocktimestamp, uint timestamp);
    error TimeExpiredError(uint blocktimestamp, uint timestamp);
    event Queue(
        bytes32 indexed txId,
        address indexed target,
        uint value,
        string func,
        bytes data,
        uint timestamp 
    );
    event Execute(
        bytes32 indexed txId,
        address indexed target,
        uint value,
        string func,
        bytes data,
        uint timestamp
    );
    event Cancel(bytes32 indexed txId);

    //最小延迟
    uint public MIN_DELAY = 10;
    //最大延迟
    uint public MAX_DELAY = 1000;
    uint public GRACE_PERIOD = 1000; //宽限时间

    address public owner;
    bytes[] txIds;
    mapping(bytes32 => bool) queued;//队列存在的映射


    constructor(){
        owner = msg.sender;
    }
    modifier onlyOwner() {
        if (msg.sender != owner){
            revert NotOwner();
        }
        _;
    }
    //创建id  ，通过所用参数进行运算产生的哈希值
    function getTxId(
        address _target,
        uint _value,
        string calldata _func,
        bytes calldata _data,
        uint _timestamp 
    ) public pure returns(bytes32) {
        return keccak256(
            abi.encode(
                _target,_value,_func,_data,_timestamp
            )
        );
    }

    //队列方法
    //_target 目标合约地址
    //_value 数值
    //_func 方法名称
    //_data 调用的方法打包后的bytes 类型code
    //_timestamp 时间戳
    function queue(
        address _target,
        uint _value,
        string calldata _func,
        bytes calldata _data,
        uint _timestamp
    ) external onlyOwner{
        // 创建id
        bytes32 txId = getTxId(_target,_value,_func,_data,_timestamp); 
        require(!queued[txId],"hasTxIds");
        // 判断时间戳
        // 时间要 block_min_time < _timestamp < block_max_time
        if(
            _timestamp < block.timestamp + MIN_DELAY ||
            _timestamp > block.timestamp + MAX_DELAY
        ){
            revert Timeerror( block.timestamp ,_timestamp);
        }

        queued[txId] = true;
        
        emit Queue(txId, _target, _value, _func, _data, _timestamp);


    }

    //执行方法
    function execute(
        address _target,
        uint _value,
        string calldata _func,
        bytes calldata _data,
        uint _timestamp
    ) external payable onlyOwner returns(bytes memory data){
        //获取id
        bytes32 txId = getTxId(_target, _value, _func, _data, _timestamp);
        require(queued[txId],"TxIds not have");
        if(_timestamp > block.timestamp){
            revert Timeerror(block.timestamp ,_timestamp);
        }
        if(_timestamp + GRACE_PERIOD > block.timestamp ){
            revert TimeExpiredError(block.timestamp, _timestamp + GRACE_PERIOD);
        }
        //队列中取出执行
        queued[txId] = false;

        //回退函数的length为0，判断不是回退函数
        if(bytes(_func).length>0){
            //bytes4(keccak256(bytes(_func)))把方法名 打包编译为4位的哈希值
            data = abi.encodePacked(
                bytes4(keccak256(bytes(_func))),_data
            );
        }else{
            //是回退函数
            data = _data;
        }

        (bool success, bytes memory res) =  _target.call{value:msg.value}(_data);

        require(success,"failed");

        emit Execute(txId, _target, _value, _func, _data, _timestamp);

        return res;
    }

    //接受主币回退函数
    receive() external payable {}

    //取消交易
    function cancel(bytes32 txId) external onlyOwner {
        require(queued[txId],"no txId");
        queued[txId] = false;
        emit Cancel(txId);
    }
}

contract TestTimeLock {
    address public timelock;

    constructor(address _timelock) {
        timelock = _timelock;
    }
    function test() external {
        require(msg.sender == timelock);
    }
}