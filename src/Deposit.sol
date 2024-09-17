// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

contract Deposit {
    address public seller;
    mapping (address => uint256) public depositTime;

    event Deposited(address indexed);
    event SellerWithdraw(address indexed, uint256 indexed);

    constructor(address _seller){
        seller = _seller;
    }

    function buyerDeposit() external payable{
       require(msg.value == 1 ether , "incorrect amount");

       uint256 _depositTime = depositTime[msg.sender];
       require(_depositTime == 0 , "already deposited");
       depositTime[msg.sender] = block.timestamp;

       emit Deposited(msg.sender);
    }

    function sellerWithdraw(address buyer) external{
        require(msg.sender == sender , "not the seller");

        uint256 _depositTime = depositTime[buyer];
        require(_depositTime != 0 , "buyer did not deposit");
        require(block.timestamp - _depositTime > 3 days , "refund period not passed");
        delete depositTime[buyer];

        emit SellerWithdraw(buyer, block.timestamp);
        (bool ok ,) = msg.sender.call{value: 1 ether}("");

        require(ok,"seller did not withdraw");
    }
}
