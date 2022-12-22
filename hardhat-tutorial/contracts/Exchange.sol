// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

// our Exchange needs to mint and create "Crypto Dev LP" tokens
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

// inheriting ERC20 for minting "Crypto Dev LP" tokens to give liquidetors (who will provide liquidity)
contract Exchange is ERC20 {

    address public cryptoDevTokenAddress;

    // Exchange is inheriting ERC20, because our exchange would keep track of Crypto Dev LP tokens
    //0x86159A7ca55FAc7dA02383bD63F30573c54bf615
    constructor(address _CryptoDevtokenAddress)
        ERC20("Crypto Druv LP Token", "CDLP")
    {
        require(
            _CryptoDevtokenAddress != address(0),
            "Token address passed is a null address"
        );
        cryptoDevTokenAddress = _CryptoDevtokenAddress;
    }

    //Returns the amount of `Crypto Dev Tokens` held by the contract
    // getReserve :- will return total no. of 'Crypto Dev Token' that held by contract
    function getReserve() public view returns (uint256) {
        return ERC20(cryptoDevTokenAddress).balanceOf(address(this));
    }

    // adding liquidity to the exchange (this contract)
    // here "_amount" is amount of Crypto Dev tokens
    function addLiquidity(uint256 _amount) public payable returns (uint256) {
        uint256 liquidity;
        uint256 ethBalance = address(this).balance;
        uint256 cryptoDevTokenReserve = getReserve();
        ERC20 cryptoDevToken = ERC20(cryptoDevTokenAddress);

        //If reserve is empaty, intake any supplied value fro 'Ether' and 'Crypto Dev' tokens because there no ratio currentaly

        if (cryptoDevTokenReserve == 0) {
            // Transfer the 'CryptoDevToken' from user's account to the contract
            cryptoDevToken.transferFrom(msg.sender, address(this), _amount);

            //Take the current ethBalnce and mint 'ethBalance' amount of LP tokens to the user.

            // 'Liquiditi' provided is equl to 'ethBalance' because this is first time user is adding 'Eth' to the contract, so whatever 'eth' contract has is equal to the one supplied by the user in the current 'addLiquidity'  call

            // 'liquidity' (LP tokens) tokens that need to minted  to the user on 'addLiquidity` call should always be proportional to the Eth specified by the user

            liquidity = ethBalance;
            _mint(msg.sender, liquidity);
        } else {
            // If the reserve is not empty, intake any user supplied value for `Ether` and determine according to the ratio how many `Crypto Dev` tokens need to be supplied to prevent any large price impacts because of the additional liquidity

            // EthReserve should be the current ethBalance subtracted by the value of ether sent by the user
            // in the current `addLiquidity` call
            uint256 ethReserve = ethBalance - msg.value;

            // Ratio should always be maintained so that there are no major price impacts when adding liquidity
            // Ratio here is -> (cryptoDevTokenAmount user can add/cryptoDevTokenReserve in the contract) = (Eth Sent by the user/Eth Reserve in the contract);
            // So doing some maths, (cryptoDevTokenAmount user can add) = (Eth Sent by the user * cryptoDevTokenReserve /Eth Reserve);
            uint256 cryptoDevTokenAmount = (msg.value * cryptoDevTokenReserve) /
                (ethReserve);
            require(
                _amount >= cryptoDevTokenAmount,
                "Amount of tokens sent is less than the minimum tokens required"
            );

            // transfer "cryptoDevTokenAmount" amount 'Crypto Dev tokens' from user account to contract
            cryptoDevToken.transferFrom(
                msg.sender,
                address(this),
                cryptoDevTokenAmount
            );

            // The amount of LP tokens that would be sent to the user should be proportional to the liquidity of
            // ether added by the user
            // Ratio here to be maintained is ->
            // (LP tokens to be sent to the user (liquidity)/ totalSupply of LP tokens in contract) = (Eth sent by the user)/(Eth reserve in the contract)
            // by some maths -> liquidity =  (totalSupply of LP tokens in contract * (Eth sent by the user))/(Eth reserve in the contract)
            liquidity = (totalSupply() * msg.value) / ethReserve;
            _mint(msg.sender, liquidity);
        }
        return liquidity;
    }


// here we are apssing that, this "_amount" of LP token user want to remove from liquidity
    function removeLiquidity(uint256 _amount)
        public returns (uint256, uint256)
    {
        require(_amount > 0, "_amount should be greater than zero");
        uint256 ethReserve = address(this).balance;

        //here totalSupply() will return total number of tokens minted till now 
        uint256 _totalSupply = totalSupply();

        // The amount of Eth that would be sent back to the user is based
        // on a ratio
        // Ratio is -> (Eth sent back to the user) / (current Eth reserve)
        // = (amount of LP tokens that user wants to withdraw) / (total supply of LP tokens)
        // Then by some maths -> (Eth sent back to the user)
        // = (current Eth reserve * amount of LP tokens that user wants to withdraw) / (total supply of LP tokens)
        uint256 ethAmount = (ethReserve * _amount) / _totalSupply;

        // The amount of Crypto Dev token that would be sent back to the user is based
        // on a ratio
        // Ratio is -> (Crypto Dev sent back to the user) / (current Crypto Dev token reserve)
        // = (amount of LP tokens that user wants to withdraw) / (total supply of LP tokens)
        // Then by some maths -> (Crypto Dev sent back to the user)
        // = (current Crypto Dev token reserve * amount of LP tokens that user wants to withdraw) / (total supply of LP tokens)
        uint256 cryptoDevTokenAmount = (getReserve() * _amount) / _totalSupply;

        // Burn the sent LP tokens from the user's wallet because they are already sent to
        // remove liquidity
        _burn(msg.sender, _amount);
        // Transfer `ethAmount` of Eth from the contract to the user's wallet
        payable(msg.sender).transfer(ethAmount);
        // Transfer `cryptoDevTokenAmount` of Crypto Dev tokens from the contract to the user's wallet
        ERC20(cryptoDevTokenAddress).transfer(msg.sender, cryptoDevTokenAmount);
        return (ethAmount, cryptoDevTokenAmount);
    }

    // 'getAmountOfToken' will Returns the amount Eth/Crypto Dev tokens that would be returned to the user in the swap
    function getAmountOfTokens(
        uint256 inputAmount,
        uint256 inputReserve,
        uint256 outputReserve
    ) public pure returns (uint256) {
        require(inputReserve > 0 && outputReserve > 0, "invalid reserve");

        // We are charging a fee of `1%`
        // Input amount with fee = (input amount - (1*(input amount)/100)) = ((input amount)*99)/100
        uint256 inputAmountWithFee = (inputAmount * 99)/100;

        // Because we need to follow the concept of `XY = K` curve
        // We need to make sure (x + Δx) * (y - Δy) = x * y
        // So the final formula is Δy = (y * Δx) / (x + Δx)
        // Δy in our case is `tokens to be received`
        // Δx = ((input amount)*99)/100, x = inputReserve, y = outputReserve
        // So by putting the values in the formula you can get the numerator and denominator
        uint256 numerator = inputAmountWithFee * outputReserve;
        uint256 denominator = inputReserve  + inputAmountWithFee;
        return numerator / denominator;
    }

    // this function will take 'eth' and return 'CryptoDev Tokens'
    function ethToCryptoDevToken(uint256 _minToken) public payable {
        uint256 tokenReserve = getReserve();
        // call the `getAmountOfTokens` to get the amount of Crypto Dev tokens
        // that would be returned to the user after the swap
        // Notice that the `inputReserve` we are sending is equal to
        // `address(this).balance - msg.value` instead of just `address(this).balance`
        // because `address(this).balance` already contains the `msg.value` user has sent in the given call
        // so we need to subtract it to get the actual input reserve
        uint256 tokensBought = getAmountOfTokens(
            msg.value,
            address(this).balance - msg.value,
            tokenReserve
        );

        require(tokensBought >= _minToken, "insufficient output amount");
        // Transfer the `Crypto Dev` tokens to the user
        ERC20(cryptoDevTokenAddress).transfer(msg.sender, tokensBought);
    }

    // this function will take 'CryptoDev Tokens' and return 'eth'
    function cryptodevTokenToEth(uint256 _tokensSold, uint256 _minEth) public {
        uint256 tokenReserve = getReserve();

        // call the `getAmountOfTokens` to get the amount of Eth that would be returned to the user after the swap
        uint256 ethBought = getAmountOfTokens(
            _tokensSold,
            tokenReserve,
            address(this).balance
        );

        require(ethBought >= _minEth, "insufficient output amount");

        // Transfer `Crypto Dev` tokens from the user's address to the contract
        ERC20(cryptoDevTokenAddress).transferFrom(
            msg.sender,
            address(this),
            _tokensSold
        );

        // send the `ethBought` to the user from the contract
        payable(msg.sender).transfer(ethBought);
    }
}
