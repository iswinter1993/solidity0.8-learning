const BigNumber = require('bignumber.js')
const Learning = artifacts.require('Learning')

contract('Learning', async accounts => {
    it('safe math', async ()=>{
        const learning = await Learning.deployed()
        const test_Safe_math = await learning.test_Safe_math({from:accounts[1]})
        const big_test_Safe_math = new BigNumber(test_Safe_math)
        const test_unSafe_math = await learning.test_unSafe_math()
        const big_test_unSafe_math = new BigNumber(test_unSafe_math)
        console.log('test_Safe_math:',big_test_Safe_math.toFixed())
        console.log('test_Safe_math:',big_test_unSafe_math.toFixed())
    })
    it('creat2',async ()=>{
        const learning = await Learning.deployed();
        const by32 = await learning.getBytes32(123);
        console.log('by32:',by32)
        await learning.createNewContract(by32)
        const addr =await learning.getdeployedAddress()
        console.log('addr:',addr)
    })
})