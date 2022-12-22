import { BigNumber, Contract, utils } from "ethers";
import {
    EXCHANGE_CONTRACT_ABI,
    EXCHANGE_CONTRACT_ADDRESS,
    TOKEN_CONTRACT_ABI,
    TOKEN_CONTRACT_ADDRESS,
} from "../constants";

//  addLiquidity helps add liquidity to the exchange, If the user is adding initial liquidity, user decides the ether and CD tokens he wants to add
// the exchange. If he is adding the liquidity after the initial liquidity has already been added
//  then we calculate the Crypto Dev tokens he can add, given the Eth he wants to add by keeping the ratios constant

export const addLiquidity = async (signer: any, addCDAmountWei: BigNumber | number, addEtherAmountWei: BigNumber ) => {
    try {
        console.log(addEtherAmountWei,'eth');
        
        // create new instance of token contract (that ICO contract)
        const tokenContract = new Contract(
            TOKEN_CONTRACT_ADDRESS,
            TOKEN_CONTRACT_ABI,
            signer
        );

        //create new instance of exchange contract
        const exchangeContract = new Contract(
            EXCHANGE_CONTRACT_ADDRESS,
            EXCHANGE_CONTRACT_ABI,
            signer
        );

        //Beacause CD tokens are ERC20, user (means here : msg.sender) need to give permission to "Exchange contract address" to take require number of CD token out of his account
        let tx = await tokenContract.approve(
            EXCHANGE_CONTRACT_ADDRESS,
            addCDAmountWei.toString()
        );

        await tx.wait();

        //After Exchange contract has the approval, add Ether and CD token to liquidity
        tx = await exchangeContract.addLiquidity(addCDAmountWei,
            { value: addEtherAmountWei }
        );

        await tx.wait();
    } catch (error) {
        console.log(error);
    }
}


//calculates the CD tokens that need to be added to the liquidity given `_addEtherAmountWei` amount of ether
export const calculateCD = async (_addEther = "0",
    etherBalanceContract: BigNumber,
    cdTokenReserve: BigNumber) => {

    // `_addEther` is a string, we need to convert it to a Bignumber before we can do our calculations
    // We do that using the `parseEther` function from `ethers.js`
    const _addEtherAmountWei = utils.parseEther(_addEther);


    // Ratio needs to be maintained when we add liquidty.
    // We need to let the user know for a specific amount of ether how many `CD` tokens
    // He can add so that the price impact is not large
    // The ratio we follow is (amount of Crypto Dev tokens to be added) / (Crypto Dev tokens Reserve balance) = (Eth that would be added) / (Eth reserve in the contract)
    // So by maths we get (amount of Crypto Dev tokens to be added) = (Eth that would be added * Crypto Dev tokens Reserve balance) / (Eth reserve in the contract)

    const cryptoDevTokenAmout = _addEtherAmountWei.mul(cdTokenReserve).div(etherBalanceContract);
    return cryptoDevTokenAmout;
}