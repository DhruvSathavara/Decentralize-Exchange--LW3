import {Contract} from "ethers";
import {  EXCHANGE_CONTRACT_ABI,
    EXCHANGE_CONTRACT_ADDRESS,
    TOKEN_CONTRACT_ABI,
    TOKEN_CONTRACT_ADDRESS, } from "../constants";


    //this function will return the Ether balance of User or Contract

    export const getEtherBalance =  async (provider : any,address : (string | null ) ,contract = false) => {
        try {
    // if the caller has set the 'contract' boolean to true return the balance of "Exchance contract"
    // if "contract" is false return the balance of user's address

    if(contract){
        const balance = await provider.getBalance(EXCHANGE_CONTRACT_ADDRESS);
        return balance;
    }else {
        const balance  = await provider.getBalance(address);
        return balance;
    }
        } catch (error) {
            console.log(error);
        }
    }


    //this function will return Crypto Dev Tokens in the account of provided address
    export const getCDTokensBalance = async (provider : any ,address: string) => {
        try {
            const tokenContract = new Contract (
                TOKEN_CONTRACT_ADDRESS,
                TOKEN_CONTRACT_ABI,
                provider
            );
            const balanceOfCryptoDevTokens = await tokenContract.balanceOf(address);
            return balanceOfCryptoDevTokens;
        } catch (error) {
            console.log(error);
            
        }
    }


    // this function will return amount of LP token in the account of provided 'address'
    export const getLPTokensBalance = async (provider : any,address : string) => {
        try {
        const exchageContract = new Contract (
            EXCHANGE_CONTRACT_ADDRESS,
            EXCHANGE_CONTRACT_ABI,
            provider
        );
        const balanceOfLPTokens = await exchageContract.balanceOf(address);
        return balanceOfLPTokens;
        } catch (error) {
            console.log(error);
        }
    }

//this function will return amount of CD tokens in the exchange contrac address

export const getReserveOfCDTokens = async (provider : any) => {
    try {
        const exchangeContract = new Contract (
            EXCHANGE_CONTRACT_ADDRESS,
            EXCHANGE_CONTRACT_ABI,
            provider
        );
        const reserve = exchangeContract.getReserve();
        return reserve;
    } catch (error) {
        console.log(error);
        
    }
}