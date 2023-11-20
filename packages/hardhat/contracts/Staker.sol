// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;  //Do not change the solidity version as it negativly impacts submission grading

import "hardhat/console.sol";
import "./ExampleExternalContract.sol";

error Staker__ErrorBalanceThresholdConditionNotMet();
error Staker__ErrorDeadlineConditionNotMet();
error Staker__ErrorDoesNotHaveEnoughStakedBalance();

contract Staker {

  ExampleExternalContract public exampleExternalContract;

  uint256 private immutable executionDeadline;
  uint256 private lastExecutionTimestamp;
  address[] private stakers;
  uint256 private stakerCount;
  mapping ( address => uint256 ) public balances;
  uint256 public constant threshold = 1 ether;

  event Stake(
    address indexed staker,
    uint256 price
  );

  modifier shouldBalanceBeAboveThreshold(bool _shouldBalanceBeAboveThreshold) {
    bool isBalanceBeAboveThreshold = address(this).balance >= threshold;
    if (_shouldBalanceBeAboveThreshold != isBalanceBeAboveThreshold) {
      revert Staker__ErrorBalanceThresholdConditionNotMet();
    }
    _;
  }

  modifier hasEnoughStakedBalance(uint256 amount) {
    if (amount > balances[msg.sender]) {
      revert Staker__ErrorDoesNotHaveEnoughStakedBalance();
    }
    _;
  }

  modifier shouldBePastDeadline(bool _shouldBePastDeadline) {
    bool isPastDeadline = timeLeft() == 0;
    if (_shouldBePastDeadline != isPastDeadline) {
      revert Staker__ErrorDeadlineConditionNotMet();
    }
    _;
  }

  constructor(address exampleExternalContractAddress) {
      stakerCount = 0;
      executionDeadline = 259200;
      lastExecutionTimestamp = block.timestamp;
      exampleExternalContract = ExampleExternalContract(exampleExternalContractAddress);
  }

  // Collect funds in a payable `stake()` function and track individual `balances` with a mapping:
  // (Make sure to add a `Stake(address,uint256)` event and emit it for the frontend `All Stakings` tab to display)
  function stake() public payable {
    balances[msg.sender] += msg.value;
    if (stakers.length == stakerCount) {
      stakers.push(msg.sender);
    }
    else {
      stakers[stakerCount] = msg.sender;
    }
    stakerCount++;
    emit Stake(msg.sender, msg.value);
  }

  // After some `deadline` allow anyone to call an `execute()` function
  // If the deadline has passed and the threshold is met, it should call `exampleExternalContract.complete{value: address(this).balance}()`
  function execute() public shouldBePastDeadline(true) {
    if (address(this).balance >= threshold) {
      for (uint i = 0; i < stakerCount; i++) {
        balances[stakers[i]] = 0;
      }
      stakerCount = 0;
      lastExecutionTimestamp = block.timestamp;
      exampleExternalContract.complete{value: address(this).balance}();
    }
  }

  // If the `threshold` was not met, allow everyone to call a `withdraw()` function to withdraw their balance
  // function withdraw(uint256 amount) public hasEnoughStakedBalance(amount) shouldBalanceBeAboveThreshold(false) {
  //   balances[msg.sender] -= msg.value;
  //   (bool success, ) = payable(msg.sender).call{value: amount}("");
  //   require(success);
  // }
  function withdraw() public shouldBalanceBeAboveThreshold(false) {
    uint256 amount = balances[msg.sender];
    if (amount != 0) {
      balances[msg.sender] = 0;
      (bool success, ) = payable(msg.sender).call{value: amount}("");
      require(success);
    }
  }

  // Add a `timeLeft()` view function that returns the time left before the deadline for the frontend
  function timeLeft() public view returns(uint256) {
    //int256 timeDelta = int256(executionDeadline) - (int256(block.timestamp) - int256(lastExecutionTimestamp));
    int timeDelta = int(executionDeadline) - (int(block.timestamp) - int(lastExecutionTimestamp));
    return timeDelta > 0 ? uint(timeDelta) : 0;
  }

  // Add the `receive()` special function that receives eth and calls stake()
  receive() external payable {
    stake();
  }

}
