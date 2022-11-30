// verify on network
module.exports = function(hre){
    return async function (contractAddress, args=[]) {
        try {
            await hre.run("verify:verify", {
                address: contractAddress,
                constructorArguments: args,
            });
        } catch (error) {
            error.message.toLowerCase().includes('already verified')
                ?console.log(`>>>>>> ${contractAddress} Already verified!\n`)
                :console.log(`\n------------------\nIf your hardhat-verify is not working, make sure the vpn is in the global state!\n------------------\n${error}`)
        }
    }
}