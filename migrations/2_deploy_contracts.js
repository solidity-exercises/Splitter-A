const Splitter = artifacts.require('../contracts/Splitter.sol');
const Destructible = artifacts.require('../contracts/common/Destructible.sol')

module.exports = (deployer) => {
    deployer.deploy(Destructible);
    deployer.deploy(Splitter);
}