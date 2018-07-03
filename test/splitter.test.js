const Splitter = artifacts.require('../contracts/Splitter.sol');

const testUtil = require('./utils/test.util.js');

contract('Splitter', (accounts) => {
    let con;
    
	beforeEach( async () => {
		con = await Splitter.new();
    });

    it('contract Should initialize members properly When created', async () => {
        const members = [accounts[1], accounts[2], accounts[3]];

        await con.init(members);

        const memberCount = await con.memberCount.call();

        assert.equal(memberCount, members.length);
    });

    it('contract Should throw When less than 3 members are initialized', async () => {
        const members = [accounts[1], accounts[2]];

        const init = con.init(members);

        await testUtil.assertRevert(init);
    });

    it('contract Should throw If it has not been initialized when other funcs are called', async () => {
        const call = con.getMemberBalance(accounts[1]);

        await testUtil.assertRevert(call);
    });

    it('init Should allow only the owner to initialize contract', async () => {
        const members = [accounts[1], accounts[2], accounts[3]];

        const init = con.init(members, {from: accounts[4]});

        await testUtil.assertRevert(init);
    });
    
    it('donate Should allow members to send the contract money', async () => {
        const members = [accounts[1], accounts[2], accounts[3]];
        const init = await con.init(members);

        const amount = web3.toWei('10', 'ether');

        await con.donate({from: accounts[1], value: amount});

        const donation = await con.getMemberDonations(accounts[1]);
        
        assert.equal(donation, amount);
    });

    it('donate Should allow members to send money which will be split among other members', async () => {
        const members = [accounts[1], accounts[2], accounts[3]];
        const init = await con.init(members);

        const amount = web3.toWei('10', 'ether');

        await con.donate({from: accounts[1], value: amount});

        const balance1 = await con.getMemberBalance(accounts[2]);
        const balance2 = await con.getMemberBalance(accounts[3]);

        assert.equal(balance1.valueOf(), web3.toWei('5', 'ether'));
        assert.equal(balance2, web3.toWei('5', 'ether'));
    });

    it('withdraw Should allow members to withdraw their money from the contract', async () => {
        const members = [accounts[1], accounts[2], accounts[3]];
        const init = await con.init(members);

        const amount = web3.toWei('10', 'ether');

        await con.donate({from: accounts[1], value: amount});

        await con.withdraw({from: accounts[2]});

        const accountBalance = await con.getMemberBalance(accounts[2]);

        assert.equal(accountBalance, 0);
    });

    it('withdraw Should not allow members to withdraw their money if their balance is 0', async () => {
        const members = [accounts[1], accounts[2], accounts[3]];
        const init = await con.init(members);

        const amount = web3.toWei('10', 'ether');

        await con.donate({from: accounts[1], value: amount});

        await con.withdraw({from: accounts[2]});
        const secondWithdraw =  con.withdraw({from: accounts[2]});

        await testUtil.assertRevert(secondWithdraw);
    });

    
});