pragma solidity ^0.4.23;

import '../contracts/common/Destructible.sol';

contract Splitter is Destructible {
    
    uint public memberCount;
    uint public totalBalance;
    
    struct Member {
        bool isMember;
        uint donations;
        uint contractBalanceAtLastWithdraw;
    }

    mapping (address=>Member) public members;

    function () public payable {} 

    modifier onlyMembers() {
        require(members[msg.sender].isMember);
        _;
    }

    function init(address[] initialMembers) public onlyOwner {
        require(initialMembers.length >= 3);
        
        for (uint i = 0; i < initialMembers.length; i++) {
            members[initialMembers[i]] = Member({isMember: true, donations: 0, contractBalanceAtLastWithdraw: 0});
        }

        memberCount = initialMembers.length;
    }

    function donate() public payable onlyMembers {
        require(msg.value > 0);

        _acknowledgeDonation(msg.sender, msg.value);
    }

    function getMemberBalance(address _member) public view returns (uint) {
        require(members[_member].isMember);

        return (getContractBalance() - members[_member].donations - members[_member].contractBalanceAtLastWithdraw) / (memberCount - 1);
    }

    function getContractBalance() public view returns (uint) {
        return address(this).balance;
    }

    function withdraw() public onlyMembers {
        require(_canWithdraw(msg.sender));

        members[msg.sender].contractBalanceAtLastWithdraw = totalBalance;

        msg.sender.transfer(getMemberBalance(msg.sender));
    }

    function _acknowledgeDonation(address _sender, uint _amount) private {
        members[_sender].donations += _amount;
    }

    function _canWithdraw(address _members) private view returns (bool) {
        return members[_members].contractBalanceAtLastWithdraw != totalBalance;
    }
}