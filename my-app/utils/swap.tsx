import { BigNumber, Contract } from "ethers";
import {
    EXCHANGE_CONTRACT_ABI,
    EXCHANGE_CONTRACT_ADDRESS,
    TOKEN_CONTRACT_ABI,
    TOKEN_CONTRACT_ADDRESS,
} from "../constants";

// Returns the number of Eth/Crypto Dev tokens that can be received when the user swaps `_swapAmountWei` amount of Eth/Crypto Dev tokens.

export const getAmountOfTokensReceivedFromSwap = async (
    _swapAmountWei:BigNumber | number,
    provider: any,
    ethSelected: boolean,
    ethBalance: BigNumber | number,
    reservedCD: BigNumber | number
) => {
    try {

        // Create a new instance of the exchange contract
        const exchangeContract = new Contract(
            EXCHANGE_CONTRACT_ADDRESS,
            EXCHANGE_CONTRACT_ABI,
            provider
        );

        let amountOfTokens;

        // If `Eth` is selected this means our input value is `Eth` which means our input amount would be
        // `_swapAmountWei`, the input reserve would be the `ethBalance` of the contract and output reserve
        // would be the `Crypto Dev` token reserve
        if (ethSelected) {
            amountOfTokens = await exchangeContract.getAmountOfTokens(
                _swapAmountWei,
                ethBalance,
                reservedCD
            );
        } else {
            // If `Eth` is not selected this means our input value is `Crypto Dev` tokens which means our input amount would be
            // `_swapAmountWei`, the input reserve would be the `Crypto Dev` token reserve of the contract and output reserve
            // would be the `ethBalance`
            amountOfTokens = await exchangeContract.getAmountOfTokens(
                _swapAmountWei,
                reservedCD,
                ethBalance
            );
        }
        return amountOfTokens;

    } catch (error) {
        console.log(error);
    }
}


// swapTokens will Swaps 'swapAmountWei'  amount of ETH/Crypto Dev tokens with 'tokenToBeReceivedAfterSwap' amount of ETH/Crypto Dev tokens
export const swapTokens = async (
    signer: any,
    swapAmountWei: BigNumber | number,
    tokenToBeReceivedAfterSwap:BigNumber | number,
    ethSelected: boolean
) => {

    // Create a new instance of the exchange contract
    const exchangeContract = new Contract(
        EXCHANGE_CONTRACT_ADDRESS,
        EXCHANGE_CONTRACT_ABI,
        signer
    );

    // create new instance of token contract (that ICO contract)
    const tokenContract = new Contract(
        TOKEN_CONTRACT_ADDRESS,
        TOKEN_CONTRACT_ABI,
        signer
    );
    let tx;

    // If Eth is selected call the `ethToCryptoDevToken` function else
    // call the `cryptoDevTokenToEth` function from the contract
    // As you can see you need to pass the `swapAmount` as a value to the function because
    // it is the ether we are paying to the contract, instead of a value we are passing to the function
    if (ethSelected) {
        tx = await exchangeContract.ethToCryptoDevToken(
            tokenToBeReceivedAfterSwap,
            {
                value: swapAmountWei,
            }
        )
    } else {

        //Beacause CD tokens are ERC20, user (means here : msg.sender) need to give permission to "Exchange contract address" to take 'swapAmountWei' number of CD token out of his account

        tx = await exchangeContract.approve(
            EXCHANGE_CONTRACT_ADDRESS,
            swapAmountWei.toString()
        );
        await tx.wait();

        // call cryptoDevTokenToEth function which would take in `swapAmountWei` of `Crypto Dev` tokens and would
        // send back `tokenToBeReceivedAfterSwap` amount of `Eth` to the user

        tx = await exchangeContract.cryptodevTokenToEth(
            swapAmountWei,
            tokenToBeReceivedAfterSwap
        )
    }
    await tx.wait();
}