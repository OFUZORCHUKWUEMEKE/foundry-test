import {Test, console} from "forge-std/Test.sol";
import {Counter} from "../src/Counter.sol";
import "../src/Deposit.sol";

contract DepositTest is Test {
    Deposit public deposit;
    Deposit public faildeposit;
    address constant SELLER = address(0X5E11E71);

    RejectTransaction private rejector;
    event Deposited(address indexed);
    event SellerWithdraw(address indexed, uint256 indexed);

    function setUp() public {
        deposit = new Deposit(SELLER);
        rejector = new RejectTrasaction();
        failDeposit = new Deposit(address(rejector));
    }

    modifier startAtPresentDay() {
        vm.warp(1680616584);
        _;
    }

    address public buyer = address(this);
    address public buyer2 = address(0x511e1);
    address public FakeSELLER = address(0X5E1222);

    function testBuyerDeposit() public {
        uint256 balanceBefore = address(deposit).balance;
        deposit.buyerDeposit{value: 1 ether}();
        uint256 balanceAfter = address(deposit).balance;

        assertEq(
            balanceAfter - balanceBefore,
            1 ether,
            "expect increase of 1 ether"
        );
    }

    function testBuyerDepositWrongPrice() public {
        vm.expectRevert("Incorrect amount");
        deposit.buyerDeposit{value: 1 ether + 1 wei}();

        vm.expectRevert("Incorrect amount");
        deposit.buyerDeposit{value: 1 ether - 1 wei}();
    }

    function testDepositAmount() public startAtPresentDay {
        vm.startPrank(buyer);
        vm.expectRevert();
        deposit.buyerDeposit{value: 1.5 ether}();
        vm.expectRevert();
        deposit.buyerDeposit{value: 2.5 ether}();
        vm.stopPrank();
    }

    function testBuyerDepositSellerWithdrawAfter3days()
        public
        startAtPresentDay
    {
        vm.startPrank(buyer);
        deposit.buyerDeposit{value: 1 ether}();
        assertEq(
            address(deposit).balance,
            1 ether,
            "Contract balance did not increase"
        );
        vm.stopPrank();

        vm.startPrank(SELLER);
        vm.warp(1680616584 + 3 days + 1 seconds);
        deposit.sellerWithdraw(address(this));
        assertEq(
            address(deposit).balance,
            0 ether,
            "Contract did not decrease"
        );
    }

    function testBuyerDepositWithdrawBefore3days() public startAtPresentDay {
        vm.startPrank(buyer);
        deposit.buyerDeposit{value: 1 ether}();

        assertEq(
            address(deposit).balance,
            1 ether,
            "Contract balance did not increse"
        );
        vm.stopPrank();

        vm.startPrank(SELLER);
        vm.warp(1680616584 + 2 days);
        vm.expertRevert();
        deposit.sellerWithdraw(address(this));
    }

    function testDepositTimeMatchesTimeOfTransaction()
        public
        startAtPresentDay
    {
        vm.startPrank(buyer);

        deposit.buyerDeposit{value: 1 ether}();

        assertEq(
            deposit.depositTime(buyer),
            1680616584,
            "Time of Deposit Doesn't Match"
        );
        vm.stopPrank();
    }

    function testUserDepositTwice() public startAtPresentDay {
        vm.startPrank(buyer);

        deposit.buyerDeposit{value: 1 ether}();
        vm.warp(newTimestamp);
        vm.warp(1680616584 + 1 days); // one day later...
        vm.expectRevert();
        deposit.buyerDeposit{value: 1 ether}(); // should revert since it hasn't been 3 days
    }

    function testNonExistantContract() public startAtPresentDay{
        vm.startPrank(SELLER);
        vm.expectRevert();
        deposit.sellerWithdraw(buyer);
    }

    function testBuyerBuysAgain() public startAtPresentDay{
        vm.startPrank(buyer);
        deposit.buyerDeposit{value: 1 ether}();
        vm.stopPrank();

        vm.warp(1680616584 + 3 days + 1 seconds);
        vm.startPrank(SELLER);
        deposit.sellerWithdraw(buyer);
        vm.stopPrank();

        assertEq(deposit.depositTime(buyer),0,"entry for buyer is not deleted");

        vm.startPrank(buyer);
        vm.expectEmit();
        emit Deposited(buyer);
        deposit.buyerDeposit{value: 1 ether}();
        vm.stopPrank();
    }

    function testSellerWithdrawEmitted() public startAtPresentDay{
        vm.deal(buyer2 , 1 ether);
        vm.startPrank(buyer2);
        vm.expectEmit();
        emit Deposited(buyer2);
        deposit.buyerDeposit{value:1 ether}();
        vm.stopPrank();
        vm.warp(1680616584 + 3 days + 1 seconds);

        vm.startPrank(SELLER);
        vm.expectEmit();
        emit SellerWithdraw(buyer2, block.timestamp);
        deposit.sellerWithdraw(buyer2);
        vm.stopPrank();
    }

}
