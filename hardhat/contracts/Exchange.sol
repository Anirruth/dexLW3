// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract Exchange is ERC20 {
    address public tokenaddress;

    constructor(address token) ERC20("ETH TOKEN LP token","lpETHToken"){
        require(token!=address(0),"zero address");
        tokenaddress = token;
    }

    function getReserve() public view returns(uint256){
        return ERC20(tokenaddress).balanceOf(address(this));
    }

    function addliquidity(uint256 tokenamount) public payable returns(uint256){
        uint256 lpTokensToMint;
        uint256 ethReserveBalance = address(this).balance;
        uint256 tokenReserveBalance = getReserve();
        ERC20 token = ERC20(tokenaddress);

        if(tokenReserveBalance == 0){
            token.transferFrom(msg.sender,address(this),tokenamount);

            lpTokensToMint=ethReserveBalance;
            _mint(msg.sender,lpTokensToMint);
            return lpTokensToMint;
        }
        uint256 ethReservePriorToFunctionCall = ethReserveBalance- msg.value;
        uint256 mintokenAmounRequired = (msg.value * tokenReserveBalance)/ethReservePriorToFunctionCall;
        require(tokenamount >= mintokenAmounRequired,"token amount less than minimum required");
        token.transferFrom(msg.sender,address(this),mintokenAmounRequired);

        lpTokensToMint=(msg.value* totalSupply())/ethReservePriorToFunctionCall;
        _mint(msg.sender,lpTokensToMint);
        return lpTokensToMint;

    }

    function removeLiquidity(uint256 amountofLPtokens) public returns(uint256,uint256){
        require(amountofLPtokens > 0 ,"amount should be greater than 0");

        uint256 ethReserveBalance = address(this).balance;
        uint256 lpTokenTotalSupply = totalSupply();

        uint256 ethtoreturn= (amountofLPtokens*ethReserveBalance)/lpTokenTotalSupply;
        uint256 tokentoReturn =(amountofLPtokens*getReserve())/lpTokenTotalSupply;

        _burn(msg.sender,amountofLPtokens);
        payable(msg.sender).transfer(ethtoreturn);
        ERC20(tokenaddress).transfer(msg.sender,tokentoReturn);
        return (ethtoreturn,tokentoReturn);
    }

    function outputfromswap(uint256 inputAmount,uint256 inputReserve, uint256 outputReserve) public pure returns(uint256){
        require(inputReserve>0 && outputReserve>0,"reserves are less than 0");

        uint256 inputAmountWithFee = inputAmount * 99;
        uint256 numerator = inputAmountWithFee * outputReserve;
        uint256 denominator = (inputAmount*100)+ inputAmountWithFee;
        return numerator/denominator;
    }

    function ethtotokenswap(uint256 mintokenstoreceive) public payable{
        uint256 tokenReserveBalance = getReserve();
        uint256 tokenstoreceive = outputfromswap(msg.value, address(this).balance-msg.value , tokenReserveBalance);
        require(tokenstoreceive >= mintokenstoreceive,"tokens to receive are less than expected");
        ERC20(tokenaddress).transfer(msg.sender,tokenstoreceive);
    }

    function tokentoethswap(uint256 tokenstoswap , uint256 minethtoreceive) public{
        uint256 tokenReserveBalance = getReserve();
        uint256 ethtoreceive = outputfromswap(tokenstoswap,tokenReserveBalance,address(this).balance);
        require(ethtoreceive >= minethtoreceive,"output amount less than minimum expected");
        ERC20(tokenaddress).transferFrom(msg.sender,address(this),tokenstoswap);
        payable(msg.sender).transfer(ethtoreceive);
    }
    

}