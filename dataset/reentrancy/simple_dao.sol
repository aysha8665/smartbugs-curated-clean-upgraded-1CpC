pragma solidity ^0.8.0;

contract SimpleDAO {
    mapping (address => uint) public credit;

    bool private _locked;

    modifier nonReentrant() {
        require(!_locked, "Reentrant call");
        _locked = true;
        _;
        _locked = false;
    }

    function donate(address to) payable public {
        credit[to] += msg.value;
    }

    function withdraw(uint amount) public nonReentrant {  
        require(credit[msg.sender] >= amount, "Insufficient credit");

        credit[msg.sender] -= amount;                

        (bool res, ) = msg.sender.call{value: amount}("");
        require(res, "Transfer failed");
    }

    function queryCredit(address to) public view returns(uint) { 
        return credit[to];
    }
}