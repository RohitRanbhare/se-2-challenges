pragma solidity 0.8.4; //Do not change the solidity version as it negativly impacts submission grading
// SPDX-License-Identifier: MIT

import "@openzeppelin/contracts/access/Ownable.sol";
import "./YourToken.sol";

error Vendor__ErrorNotAContractOwner();

contract Vendor is Ownable {

  YourToken public yourToken;
  uint256 public constant tokensPerEth = 100;

  event BuyTokens(address buyer, uint256 amountOfETH, uint256 amountOfTokens);

  constructor(address tokenAddress) {
    yourToken = YourToken(tokenAddress);
  }

  // ToDo: create a payable buyTokens() function:
  function buyTokens() public payable {
    uint256 amountOfYourToken = msg.value * tokensPerEth;
    bool success = yourToken.transfer(msg.sender, amountOfYourToken);
    require(success);
    emit BuyTokens(msg.sender, amountOfYourToken, msg.value);
  }

  // ToDo: create a withdraw() function that lets the owner withdraw ETH
  function withdraw() public onlyOwner {
    (bool success, ) = payable(owner()).call{value: address(this).balance}("");
    require(success);
  }

  // ToDo: create a sellTokens(uint256 _amount) function:
  function sellTokens(uint256 amount) public {
    yourToken.approve(address(this), amount);
    yourToken.transferFrom(msg.sender, address(this), amount);
    uint256 amountOfEth = amount / tokensPerEth;
    (bool success, ) = payable(msg.sender).call{value: amountOfEth}("");
    require(success);
  }
}
