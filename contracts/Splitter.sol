pragma solidity ^0.4.23;

import '../contracts/common/Destructible.sol';
import '../contracts/common/SafeMath.sol';

contract Splitter is Destructible {
    
    using SafeMath for uint;

    uint public memberCount;
    uint public totalBalance;
    
    struct Member {
        bool isMember;
        uint donations;
        uint contractBalanceAtLastWithdraw;
        uint contractBalanceAtCreation;
    }

    mapping (address=>Member) public members;

    function () public payable {} 

    modifier onlyMembers() {
        require(members[msg.sender].isMember);
        _;
    }

    modifier postInit() {
        require(memberCount >= 3);
        _;
    }

    function init(address[] initialMembers) public onlyOwner {
        require(initialMembers.length >= 3);
        
        for (uint i = 0; i < initialMembers.length; i++) {
            members[initialMembers[i]] = Member({isMember: true, donations: 0, contractBalanceAtLastWithdraw: 0, contractBalanceAtCreation: totalBalance});
        }

        memberCount = initialMembers.length;
    }

    function donate() public payable onlyMembers postInit {
        require(msg.value > 0);

        _acknowledgeDonation(msg.sender, msg.value);
    }

    function getMemberBalance(address _member) public view postInit returns (uint) {
        require(members[_member].isMember);

        return (totalBalance.sub(members[_member].donations)
                            .sub(members[_member].contractBalanceAtLastWithdraw)
                            .sub(members[_member].contractBalanceAtCreation))
                            .div((memberCount.sub(1)));
    }

    function getContractBalance() public view postInit returns (uint) {
        return address(this).balance;
    }

    function addMember(address _newMember) public postInit onlyOwner {
        _addArtificialBalancer();

        memberCount = memberCount.add(1);

        members[_newMember] = Member({isMember: true, donations: 0, contractBalanceAtLastWithdraw: 0, contractBalanceAtCreation: totalBalance});
    }

    function withdraw() public onlyMembers postInit {
        require(_canWithdraw(msg.sender));

        members[msg.sender].contractBalanceAtLastWithdraw = totalBalance;

        msg.sender.transfer(getMemberBalance(msg.sender));
    }

    function getMemberDonations(address _member) public view returns (uint) {
        return members[_member].donations;
    }

    function isMember(address _member) public view returns (bool) {
        return members[_member].isMember;
    }

    function _acknowledgeDonation(address _sender, uint _amount) private {
        members[_sender].donations = members[_sender].donations.add(_amount);
        totalBalance = totalBalance.add(_amount);
    }

    function _canWithdraw(address _members) private view returns (bool) {
        return members[_members].contractBalanceAtLastWithdraw != totalBalance;
    }

    // When adding new member this function is called so as to make the mathematical logic
    // behind the contract valid. Without this function the getMemberBalance function will not
    // return the correct value since memberCount is bigger by one. This function does not affect the
    // contract balance, only the logic
    function _addArtificialBalancer() private {
        totalBalance = totalBalance.add((totalBalance.div(memberCount.sub(1))));
    }
}